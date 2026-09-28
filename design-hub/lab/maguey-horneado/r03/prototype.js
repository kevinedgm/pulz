// Kiwi F2 simulator: local memory only; never calls a backend.
const $ = (id) => document.getElementById(id);
const esc = (value) => String(value).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const kg = (value) => Number(value || 0).toLocaleString('es-MX', { maximumFractionDigits: 3 }) + ' kg';
const S = { w: Math.min(innerWidth, 1440), state: 'm-default', drafts: {}, returnLabel: '', result: null };
const key = () => S.state.startsWith('m-') && ['m-recepcion','m-sincat','m-error'].includes(S.state) ? 'reception' : S.state.startsWith('h-abrir') || S.state === 'h-review' ? 'opening' : S.state === 'h-cerrar' ? 'close' : S.state === 'h-cocido' ? 'cooked' : null;
function remember() {
  const k = key(); if (!k) return;
  const fields = [...document.querySelectorAll('#wf-view input, #wf-view select, #wf-overlay input, #wf-overlay select')];
  if (!fields.length) return;
  S.drafts[k] = Object.fromEntries(fields.map(i => [i.id, i.value]));
  const details = document.querySelector('#wf-view details');
  if (details) S.drafts[k].detailsOpen = details.open;
}
function restore() {
  const d = S.drafts[key()]; if (!d) return;
  for (const [id,value] of Object.entries(d)) if ($(id)) $(id).value = value;
  const details = document.querySelector('#wf-view details');
  if (details) details.open = !!d.detailsOpen;
}
function setFrame() {
  $('wf-frame').style.setProperty('--wf-w', S.w + 'px');
  $('wf-label').style.setProperty('--wf-w', S.w + 'px');
  const actual = Math.min(S.w, innerWidth);
  $('wf-label').textContent = `Ejemplo F2 · marco ${actual}px · ${actual < 600 ? 'compact' : actual < 1024 ? 'medium' : 'expanded'} · no guarda datos`;
  document.querySelectorAll('[data-w]').forEach(b => b.setAttribute('aria-pressed', String(+b.dataset.w === S.w)));
}
function fieldError(input, message) {
  const id = input.id + '-error';
  let node = $(id);
  if (!node) { node = document.createElement('p'); node.id = id; node.className = 'mh-error wf-small'; node.setAttribute('aria-live','polite'); input.closest('.wf-field').append(node); }
  node.textContent = message; node.hidden = !message;
  input.setAttribute('aria-invalid', String(!!message));
  if (message) input.setAttribute('aria-describedby', id); else input.removeAttribute('aria-describedby');
}
function update() {
  const inputs = [...document.querySelectorAll('[data-saldo]')];
  if (inputs.length) {
    let valid = true, total = 0;
    inputs.forEach(i => {
      const n = Number(i.value); total += Number.isFinite(n) ? n : 0;
      const error = !i.validity.valid ? n > Number(i.dataset.saldo) ? `Solo hay ${kg(i.dataset.saldo)}. Reduce la cantidad.` : 'Usa kilos positivos, con hasta tres decimales, o deja vacío.' : '';
      if (error) valid = false;
      fieldError(i,error);
    });
    $('kg-total').textContent = kg(total);
    document.querySelectorAll('.mh-form button[type="submit"]').forEach(b => { b.disabled = !valid || total <= 0; b.setAttribute('aria-disabled',String(b.disabled)); b.textContent = 'Revisar Horno 1 con ' + kg(total); });
  }
  if ($('kg')) document.querySelectorAll('.mh-form button[type="submit"]').forEach(b => { b.disabled = !$('kg').checkValidity(); b.textContent = $('kg').value ? 'Registrar ' + kg($('kg').value) : 'Registrar recepción'; });
  if ($('ct')) {
    $('ct-hint').textContent = $('ct').value && $('ct').value < '2026-09-28T09:00' ? 'La fecha de cierre precede al inicio (28 sep 2026, 09:00). Revisa el dato antes de registrar; este aviso no añade una regla dura.' : 'Inicio: 28 sep 2026, 09:00. Revisa la fecha real del cierre.';
    const n = Number($('kc').value);
    document.querySelector('.mh-drawer .mh-warn').textContent = `Diferencia: ${kg(5200 - n)} (5,200 kg cargados → ${kg(n)} cocidos).`;
    const b = document.querySelector('.mh-drawer .wf-btn--primary');
    b.disabled = !$('kc').checkValidity() || !$('ct').value;
    b.textContent = 'Cerrar con ' + kg(n) + ' cocidos'; b.dataset.action = 'close-save';
  }
  if ($('ck')) { const b = document.querySelector('.mh-drawer .wf-btn--primary'); b.disabled = !$('ck').checkValidity(); b.textContent = $('ck').value ? 'Registrar ' + kg($('ck').value) + ' de cocido' : 'Registrar cocido'; b.dataset.action = 'cooked-save'; }
}
V['h-readonly'] = () => horneadoLista({dis:true});
V['h-operador'] = () => horneadoLista({operador:true,dis:true}) + '<p>Solo el administrador o un productor pueden registrar y cerrar horneadas.</p>';
V['h-loading'] = () => V['m-loading']();
V['h-error'] = () => '<section class="wf-state" role="alert"><h2>No pudimos cargar las horneadas</h2><p>Revisa tu conexión y vuelve a intentarlo.</p><button class="wf-btn" data-go="h-default">Reintentar</button></section>';
V['m-success'] = () => `<section class="mh-form"><h2>Recepción registrada (simulación)</h2><p role="status"><b>${kg(S.result?.quantity ?? 2000)}</b> · MAG-EJEMPLO${S.result?.species ? ' · '+esc(S.result.species) : ' · especie sin especificar'}</p><p>El lote queda con saldo para Horneado. No se guardó en la base.</p><button class="wf-btn" data-go="m-default">Volver a Maguey</button></section>`;
V['h-success'] = () => `<section class="mh-form"><h2>HOR-003 cerrada (simulación)</h2><p role="status">AC-003 · <b>${kg(S.result?.quantity ?? 4900)}</b> cocidos.</p><button class="wf-btn" data-action="handoff">Llenar tinas</button><button class="wf-btn" data-go="h-default">Volver a Horneado</button></section>`;
V['h-cooked-success'] = () => `<section class="mh-form"><h2>Cocido registrado (simulación)</h2><p role="status"><b>${kg(S.result?.quantity ?? 1500)}</b> · carga inicial sin historia.</p><button class="wf-btn" data-action="handoff">Llenar tinas</button><button class="wf-btn" data-go="h-default">Volver a Horneado</button></section>`;
V['h-conflict'] = () => '<section class="wf-state" role="alert"><h2>HOR-003 ya fue cerrada</h2><p>Otra persona registró su cierre. Tu borrador se conserva durante esta sesión del prototipo.</p><button class="wf-btn" data-go="h-success">Ver cierre registrado</button></section>';
function review() {
  const d = S.drafts.opening || {}, a = Number(d.k1 || 0), b = Number(d.k2 || 0);
  return `<section class="mh-review"><h2 tabindex="-1" id="review-title">Revisar carga de Horno 1</h2><ul>${a > 0 ? `<li>MAG-003 · Tobalá: <b>${kg(a)}</b></li>` : ''}${b > 0 ? `<li>MAG-002 · Espadín: <b>${kg(b)}</b></li>` : ''}</ul><p><b>${kg(a+b)} en total</b></p><p>Inicio: ${esc(d.ce || 'Sin fecha')} · Folio: ${esc(d.fh || 'automático')}</p><p>Al abrir se descuenta este maguey. Esta acción no se deshace desde Horneado.</p><div class="wf-actions"><button class="wf-btn wf-btn--primary" data-action="open-save" ${a+b > 0 ? '' : 'disabled'}>Abrir Horno 1 con ${kg(a+b)}</button><button class="wf-btn" data-go="h-abrir">Volver a cantidades</button></div><span class="wf-note">Simulación local, sin persistencia ni RPC.</span></section>`;
}
V['h-review'] = review;
V['h-open-success'] = () => `<section class="mh-form"><h2>Horneada abierta (simulación)</h2><p role="status">Horno 1 · <b>${kg(S.result?.quantity)}</b> cargados.</p><button class="wf-btn" data-go="h-default">Volver a Horneado</button></section>`;
OV['h-menu'] = () => '<dialog class="mh-drawer mh-menu" aria-labelledby="menu-title"><h2 id="menu-title">Acciones de HOR-003</h2><button class="wf-btn" data-go="h-cerrar">Cerrar horneada</button><button class="wf-btn" data-action="dismiss">Volver</button></dialog>';
V['h-menu'] = () => horneadoLista();
V['destinos'] = () => horneadoLista();
OV['destinos'] = () => '<dialog class="mh-drawer mh-menu" aria-labelledby="destinos-title"><h2 id="destinos-title">Destinos del proceso</h2><button class="wf-btn" data-go="m-default">Maguey</button><button class="wf-btn" data-go="h-default">Horneado</button><button class="wf-btn" data-action="dismiss">Volver</button></dialog>';
function render({focus = true} = {}) {
  const st = S.state, esM = st.startsWith('m-'), overlay = !!OV[st];
  const isForm = ['m-recepcion','m-sincat','m-error','h-abrir','h-abrir-saldo','h-abrir-sin','h-review'].includes(st);
  const noPrimary = st.endsWith('success') || st.endsWith('conflict') || st.endsWith('loading') || st.endsWith('error') || ['m-empty','h-empty','h-sinhornos'].includes(st);
  const o = st.endsWith('operador') ? {operador:true} : {dis:st.endsWith('offline') || st.endsWith('readonly'),sinPrim:noPrimary};
  $('wf-side').innerHTML = side(esM ? 'Maguey' : 'Horneado');
  document.querySelectorAll('#wf-side li').forEach(li => { const label = li.textContent; const goTo = {'Maguey':'m-default','Horneado':'h-default'}[label]; li.innerHTML = goTo ? `<button class="mh-destination" data-go="${goTo}">${label}</button>` : `<span class="mh-destination" aria-disabled="true">${label}</span>`; });
  $('wf-top').innerHTML = isForm ? topSub(esM ? 'Recepción' : 'Abrir horneada',esM ? 'Maguey':'Horneado') : topLista(esM?'Maguey':'Horneado',esM?'Registrar recepción':'Abrir horneada',o);
  $('wf-view').innerHTML = (V[st] || V['h-default'])();
  $('wf-fab').innerHTML = !isForm && !noPrimary ? fab(esM?'Registrar recepción':'Abrir horneada',o) : '';
  const previous = document.querySelector('dialog[open]'); if (previous) previous.close();
  $('wf-overlay').innerHTML = overlay ? OV[st]() : '';
  $('wf-banner').innerHTML = st.endsWith('offline') ? '<p class="wf-banner" role="status"><b>Sin conexión.</b> Puedes consultar; para registrar necesitas señal.</p>' : st.endsWith('readonly') ? '<p class="wf-banner" role="status"><b>Solo lectura.</b> Puedes consultar, no registrar.</p>' : '';
  // Initial error fixture only: once edited, the actual draft becomes authoritative.
  if (st === 'h-abrir-saldo' && !S.drafts.opening) S.drafts.opening = {k1:'2000',k2:'1500',ce:'2026-09-28T12:00',fh:''};
  restore(); update(); setFrame(); $('wf-state').value = st;
  const dialog = document.querySelector('dialog');
  if (dialog) {
    dialog.addEventListener('cancel', e => {e.preventDefault(); dismiss();});
    dialog.addEventListener('keydown', e => {
      if (e.key !== 'Tab') return;
      const controls = [...dialog.querySelectorAll('input,select,textarea,button,a[href],[tabindex]')].filter(el => !el.disabled && el.tabIndex >= 0 && !el.hidden && el.getClientRects().length);
      const first = controls[0], last = controls.at(-1);
      if (!first) {e.preventDefault(); return;}
      if (e.shiftKey && document.activeElement === first) {e.preventDefault(); last.focus();}
      else if (!e.shiftKey && document.activeElement === last) {e.preventDefault(); first.focus();}
    });
    dialog.showModal();
    (dialog.querySelector('input,button') || dialog).focus();
  } else if (focus) ($('review-title') || $('wf-view')).focus();
}
function go(state, trigger) {
  remember();
  if (OV[state] && !document.querySelector('dialog[open]')) S.returnLabel = trigger?.textContent.trim() || (state === 'h-cerrar' ? 'Cerrar horneada' : state === 'h-cocido' ? 'Cocido que ya tenía' : 'Más');
  S.state = state; render();
}
function dismiss() {
  remember(); S.state = 'h-default'; render({focus:false});
  const target = [...document.querySelectorAll('button,a')].find(b => b.textContent.trim() === S.returnLabel && b.getClientRects().length);
  (target || $('wf-view')).focus();
}
document.addEventListener('input', e => {if(e.target.closest('#wf-view,#wf-overlay')){remember(); update();}});
document.addEventListener('change', e => {if(e.target.closest('#wf-view,#wf-overlay')){remember(); update();}});
document.addEventListener('submit', e => {
  e.preventDefault(); remember();
  if (!e.target.checkValidity()) return;
  if (S.state.startsWith('h-abrir')) { update(); const b = document.querySelector('.mh-form button[type="submit"]'); if (!b || b.disabled) return; go('h-review'); }
  else if ($('kg')?.checkValidity()) { S.result = {quantity:$('kg').value,species:$('especie')?.value || ''}; go('m-success'); }
});
document.addEventListener('click', e => {
  const action = e.target.closest('button,a'); if(!action) return;
  if (action.dataset.w) {remember(); S.w = +action.dataset.w; setFrame(); return;}
  if (action.closest('.wf-ctl')) return;
  if (action.disabled || action.getAttribute('aria-disabled') === 'true') {e.preventDefault(); return;}
  const label = action.textContent.trim();
  if (action.dataset.go) {e.preventDefault(); go(action.dataset.go, action); return;}
  const kind = action.dataset.action;
  if (kind === 'dismiss' || label === 'Cancelar' || label === 'Volver') {
    e.preventDefault(); if(document.querySelector('dialog[open]')) dismiss(); else go(S.state.startsWith('m-') ? 'm-default':'h-default'); return;
  }
  if (kind === 'open-save') {remember(); const d=S.drafts.opening; S.result={quantity:Number(d.k1||0)+Number(d.k2||0)}; go('h-open-success'); return;}
  if (kind === 'close-save' || kind === 'cooked-save') {remember(); S.result={quantity:$(kind === 'close-save'?'kc':'ck').value}; go(kind === 'close-save'?'h-success':'h-cooked-success'); return;}
  if (kind === 'destinos') {go('destinos',action);return;}
  if (kind === 'handoff' || ['Llenar tinas','Ir a Recursos','Agregar en Catálogos','Ver'].includes(label)) {e.preventDefault(); $('wf-banner').innerHTML='<p class="wf-banner" role="status">Fin del recorrido de este F2. La pantalla de destino existente queda fuera de esta ronda; no se ha guardado ningún dato.</p>';return;}
  const routes={'Registrar recepción':'m-recepcion','Abrir horneada':'h-abrir','Cocido que ya tenía':'h-cocido','Cerrar horneada':'h-cerrar','Más':'h-menu','Ir a Maguey':'m-default'};
  if(routes[label]) {e.preventDefault();go(routes[label],action);}
  if (/^[←‹]/.test(label)) {e.preventDefault();go(S.state.startsWith('m-')?'m-default':'h-default');}
});
$('wf-state').addEventListener('change', e => go(e.target.value));
$('wf-notes').addEventListener('change', e => document.body.classList.toggle('wf-no-notes', !e.target.checked));
addEventListener('resize',setFrame);
render({focus:false});
