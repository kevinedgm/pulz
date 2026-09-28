import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
const requireWeb = createRequire(new URL('../../../../apps/web/package.json',import.meta.url));
const { JSDOM } = requireWeb('jsdom');
const html = readFileSync(new URL('index.html',import.meta.url),'utf8').replace('<script src="prototype.js"></script>','');
const script = readFileSync(new URL('prototype.js',import.meta.url),'utf8');
function setup() {
  const errors = [];
  const dom = new JSDOM(html,{runScripts:'dangerously',url:'http://localhost/',beforeParse(w){
    // JSDOM does not implement the browser top layer; keyboard/trap are browser QA.
    w.HTMLDialogElement.prototype.showModal=function(){this.setAttribute('open','');};
    w.HTMLDialogElement.prototype.close=function(){this.removeAttribute('open');};
    w.addEventListener('error',e=>errors.push(e.message));
  }});
  dom.window.eval(script);
  const d=dom.window.document;
  const state=s=>{d.getElementById('wf-state').value=s;d.getElementById('wf-state').dispatchEvent(new dom.window.Event('change',{bubbles:true}));};
  const fill=(id,value)=>{const e=d.getElementById(id);e.value=value;e.dispatchEvent(new dom.window.Event('input',{bubbles:true}));};
  const submit=()=>d.querySelector('form').dispatchEvent(new dom.window.Event('submit',{bubbles:true,cancelable:true}));
  const button=t=>[...d.querySelectorAll('button')].find(b=>b.textContent.trim()===t);
  return {dom,d,state,fill,submit,button,errors};
}
test('MH-MINIMAL-02: optional fields have no silent values; kilos start empty',()=>{
  const t=setup();t.state('m-recepcion');
  for(const id of ['kg','pi','especie','predio','proveedor','no']) assert.equal(t.d.getElementById(id).value,'',id);
  assert.ok(t.d.querySelector('button[type=submit]').disabled);
  t.fill('kg','123.5');t.submit();assert.match(t.d.getElementById('wf-view').textContent,/123.5 kg/);assert.doesNotMatch(t.d.getElementById('wf-view').textContent,/Tobalá/);t.dom.window.close();
});
test('MH-STATE-02: review/back and frame changes preserve every opening field',()=>{
  const t=setup();t.state('h-abrir');
  t.fill('k1','123.456');t.fill('k2','87');t.fill('ce','2026-09-28T14:05');t.fill('fh','MI-HORNO');
  t.submit();assert.match(t.d.getElementById('wf-view').textContent,/210.456 kg/);
  t.button('Volver a cantidades').click();
  for(const [id,v] of Object.entries({k1:'123.456',k2:'87',ce:'2026-09-28T14:05',fh:'MI-HORNO'})) assert.equal(t.d.getElementById(id).value,v);
  const input=t.d.getElementById('k1');t.d.querySelector('[data-w="390"]').click();assert.equal(t.d.getElementById('k1'),input);assert.equal(input.value,'123.456');t.dom.window.close();
});
test('MH-DATA-02: coherent closing fixture and warning without new hard rule',()=>{
  const t=setup();t.state('h-cerrar');assert.equal(t.d.getElementById('ct').value,'2026-09-28T12:00');
  t.fill('ct','2026-09-28T08:00');assert.match(t.d.getElementById('ct-hint').textContent,/precede/);
  t.fill('ct','2026-09-28T13:00');assert.doesNotMatch(t.d.getElementById('ct-hint').textContent,/precede/);t.dom.window.close();
});
test('MH-ERROR-02: create and clear error, invalid state and description together',()=>{
  const t=setup();t.state('h-abrir');t.fill('k2','1500');
  assert.equal(t.d.getElementById('k2').getAttribute('aria-invalid'),'true');assert.equal(t.d.getElementById('k2').getAttribute('aria-describedby'),'k2-error');assert.match(t.d.getElementById('k2-error').textContent,/1,300 kg/);assert.ok(t.d.querySelector('button[type=submit]').disabled);
  t.fill('k2','1000');assert.equal(t.d.getElementById('k2').getAttribute('aria-invalid'),'false');assert.equal(t.d.getElementById('k2').getAttribute('aria-describedby'),null);assert.ok(t.d.getElementById('k2-error').hidden);assert.equal(t.d.getElementById('k2-error').textContent,'');assert.equal(t.d.querySelector('button[type=submit]').disabled,false);t.dom.window.close();
});
test('MH-UNIT-02: units survive decimals, empty and review',()=>{
  const t=setup();t.state('h-abrir');assert.equal(t.d.getElementById('kg-total').textContent,'0 kg');
  t.fill('k1','0.125');t.fill('k2','1.5');assert.equal(t.d.getElementById('kg-total').textContent,'1.625 kg');
  t.submit();assert.match(t.d.getElementById('wf-view').textContent,/1.625 kg en total/);t.dom.window.close();
});
test('closure and cooked-entry summaries reflect edited quantities',()=>{
  const t=setup();t.state('h-cerrar');t.fill('kc','4321');t.d.querySelector('[data-action=close-save]').click();assert.match(t.d.getElementById('wf-view').textContent,/4,321 kg/);
  t.state('h-cocido');assert.ok(t.d.querySelector('[data-action=cooked-save]').disabled);t.fill('ck','90');t.d.querySelector('[data-action=cooked-save]').click();assert.match(t.d.getElementById('wf-view').textContent,/90 kg/);t.dom.window.close();
});
test('restricted states do not navigate through disabled primary actions',()=>{
  const t=setup();for(const state of ['m-offline','h-offline','m-readonly','h-readonly']) {t.state(state);const before=t.d.getElementById('wf-state').value;t.d.querySelector('#wf-top [aria-disabled=true]')?.click();assert.equal(t.d.getElementById('wf-state').value,before);}
  t.dom.window.close();
});
test('every declared state renders without JS errors, duplicate IDs or orphan ARIA descriptions',()=>{
  const t=setup();const states=[...t.d.getElementById('wf-state').options].map(o=>o.value);
  for(const s of states){t.state(s);const ids=[...t.d.querySelectorAll('[id]')].map(e=>e.id);assert.equal(new Set(ids).size,ids.length,s);for(const e of t.d.querySelectorAll('[aria-describedby],[aria-labelledby]'))for(const id of (e.getAttribute('aria-describedby')||e.getAttribute('aria-labelledby')).split(' '))assert.ok(t.d.getElementById(id),s+': '+id);}
  assert.deepEqual(t.errors,[]);t.dom.window.close();
});
test('restricted row menu cannot bypass closing permissions',()=>{
  const t=setup();for(const state of ['h-operador','h-offline','h-readonly']){t.state(state);const menu=t.d.querySelector('.mh-row button[aria-haspopup]');assert.ok(menu.disabled);assert.equal(menu.getAttribute('aria-haspopup'),'dialog');menu.click();assert.equal(t.d.getElementById('wf-state').value,state);}t.dom.window.close();
});
test('subheader back returns to the matching destination and preserves draft',()=>{
  const t=setup();t.state('h-abrir');t.fill('k1','90');t.d.querySelector('#wf-top a').click();assert.equal(t.d.getElementById('wf-state').value,'h-default');t.state('h-abrir');assert.equal(t.d.getElementById('k1').value,'90');t.state('m-recepcion');t.d.querySelector('#wf-top a').click();assert.equal(t.d.getElementById('wf-state').value,'m-default');t.dom.window.close();
});
test('optional invalid piñas cannot be submitted',()=>{
  const t=setup();t.state('m-recepcion');t.fill('kg','50');t.fill('pi','-1');t.submit();assert.equal(t.d.getElementById('wf-state').value,'m-recepcion');t.dom.window.close();
});

test('compact navigation preserves full destinations and documents the real primary',()=>{
 const t=setup();const nav=t.d.querySelector('.mh-bottom');assert.match(nav.textContent.replaceAll('\u00ad',''),/FermentaciónDestilación/);assert.equal(nav.children.length,5);t.state('m-default');assert.match(t.d.getElementById('wf-view').textContent,/cabecera en compact/);assert.doesNotMatch(t.d.getElementById('wf-view').textContent,/FAB en compact/);t.dom.window.close();
});
