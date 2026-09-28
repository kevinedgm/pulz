// Explicitly authorized, disposable r06 fixtures. No demo users, resets or DDL.
import { spawnSync } from "node:child_process"
import { randomBytes, randomUUID, createHash } from "node:crypto"
import {
  readFileSync,
  writeFileSync,
  mkdirSync,
  mkdtempSync,
  unlinkSync,
  existsSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { resolve } from "node:path"
import { createRequire } from "node:module"
import assert from "node:assert/strict"

const root = resolve(import.meta.dirname, "..")
const project = "ypgeiyorgktshgbzhgfh"
assert.equal(readFileSync(resolve(root, "supabase/.temp/project-ref"), "utf8").trim(), project)
const out = resolve(root, "design-hub/lab/maguey-horneado/r06/evidence")
mkdirSync(out, { recursive: true })
const json = (name, value) =>
  writeFileSync(resolve(out, name), JSON.stringify(value, null, 2) + "\n")
const q = (value) => `'${String(value).replaceAll("'", "''")}'`
const temp = mkdtempSync(resolve(tmpdir(), "pulz-mh-r06-"))
function sql(statement, name) {
  const file = resolve(temp, `${name}.sql`)
  writeFileSync(file, statement, { mode: 0o600 })
  try {
    const r = spawnSync(
      "supabase",
      ["db", "query", "--linked", "--project-ref", project, "-f", file, "--output", "json"],
      { cwd: root, encoding: "utf8", timeout: 60_000, maxBuffer: 4_000_000 },
    )
    // Never dump SQL or CLI stderr: setup SQL contains ephemeral credentials.
    if (r.error || r.status !== 0)
      throw Error(`SQL ${name} failed (${r.status ?? r.error?.code}); no SQL/credentials logged`)
    const parsed = JSON.parse(r.stdout.slice(r.stdout.indexOf("{")))
    assert(Array.isArray(parsed.rows), `SQL ${name}: unexpected response`)
    return parsed.rows
  } finally {
    unlinkSync(file)
  }
}
if (process.argv.includes("--cleanup")) {
  const m = JSON.parse(readFileSync(resolve(out, "manifest.json"), "utf8"))
  assert.equal(m.project, project)
  assert.match(m.tag, /^qa-mh-r06-[0-9a-f]{8}$/)
  const cleanupFile = resolve(out, "cleanup.sql")
  assert.equal(
    createHash("sha256").update(readFileSync(cleanupFile)).digest("hex"),
    m.cleanupSha256,
  )
  json("cleanup.json", sql(readFileSync(cleanupFile, "utf8"), "cleanup"))
  if (m.credentialsFile && existsSync(m.credentialsFile)) unlinkSync(m.credentialsFile)
  console.log("Scoped cleanup finished; inspect cleanup.json")
  process.exit(0)
}
assert(!existsSync(resolve(out, "manifest.json")), "r06 already exists: never overwrite a run")
const tag = `qa-mh-r06-${randomUUID().slice(0, 8)}`
const orgs = ["a", "b"].map((suffix) => ({ id: randomUUID(), slug: `${tag}-${suffix}` }))
const [A, B] = orgs.map((o) => o.id)
const users = ["admin", "productor", "operador", "admin-b"].map((role, i) => ({
  id: randomUUID(),
  role: role === "admin-b" ? "admin" : role,
  org: i === 3 ? B : A,
  email: `${tag}-${role}@example.invalid`,
  password: randomBytes(24).toString("base64url"),
}))
const oven = randomUUID(),
  tina = randomUUID(),
  tina2 = randomUUID(),
  species = randomUUID(),
  predio = randomUUID(),
  supplier = randomUUID()
const orgList = orgs.map((o) => q(o.id)).join(",")
const userList = users.map((u) => q(u.id)).join(",")
const scopedTables = [
  "fermentation_cycles",
  "formulation_supplies",
  "formulation_inputs",
  "formulations",
  "roasting_run_inputs",
  "roasting_runs",
  "liquid_movements",
  "lot_lineage",
  "operation_warnings",
  "maguey_receptions",
  "lot_external_sources",
  "lots",
  "operations",
]
const cleanup = `begin;
set local statement_timeout='20s';
set local lock_timeout='5s';
do $$ begin
${orgs.map((o) => `if exists(select 1 from organizations where id=${q(o.id)} and slug<>${q(o.slug)}) then raise exception 'Fixture org identity mismatch'; end if;`).join("\n")}
${users.map((u) => `if exists(select 1 from auth.users where id=${q(u.id)} and email<>${q(u.email)}) then raise exception 'Fixture user identity mismatch'; end if;`).join("\n")}
end $$;
delete from auth.refresh_tokens where user_id in (${userList});
delete from auth.sessions where user_id in (${userList});
${scopedTables.map((t) => `delete from public.${t} where organization_id in (${orgList});`).join("\n")}
delete from organizations where id in (${orgList});
delete from auth.users where id in (${userList});
commit;
select 'organizations' as entity,count(*)::int as remaining from organizations where id in (${orgList})
union all select 'users',count(*)::int from auth.users where id in (${userList})
union all select 'profiles',count(*)::int from profiles where id in (${userList})
union all select 'sessions',count(*)::int from auth.sessions where user_id in (${userList})
union all select 'refresh_tokens',count(*)::int from auth.refresh_tokens where user_id in (${userList})
${scopedTables.map((t) => `union all select '${t}',count(*)::int from public.${t} where organization_id in (${orgList})`).join("\n")};`
writeFileSync(resolve(out, "cleanup.sql"), cleanup)
const credentialsFile = resolve(temp, "browser-credentials.json")
// El manifiesto nunca lleva contraseñas (viven solo en credentialsFile, 0600)
const sinContrasena = (u) => Object.fromEntries(Object.entries(u).filter(([k]) => k !== "password"))
const manifest = {
  project,
  tag,
  orgs,
  users: users.map(sinContrasena),
  oven,
  tina,
  tina2,
  species,
  predio,
  supplier,
  credentialsFile,
  cleanupSha256: createHash("sha256").update(cleanup).digest("hex"),
  authorized:
    "User explicitly approved two isolated qa-mh-r06 tenants, reception/open/close/cooked/Formulation and exact fixture cleanup.",
  createdAt: new Date().toISOString(),
}
json("manifest.json", manifest)
const fingerprintSQL = `begin;
create function pg_temp.fixture_baseline() returns table(entity text, rows bigint, hash text) language plpgsql as $$
declare t record; condition text; begin
for t in select tablename from pg_tables where schemaname='public' order by tablename loop
 condition := case when t.tablename='organizations' then 'id not in (${orgList.replaceAll("'", "''")})'
 when t.tablename='profiles' then 'id not in (${userList.replaceAll("'", "''")})'
 when exists(select 1 from information_schema.columns where table_schema='public' and table_name=t.tablename and column_name='organization_id') then 'organization_id not in (${orgList.replaceAll("'", "''")}) or organization_id is null'
 else 'true' end;
 return query execute format('select %L,count(*),md5(coalesce(string_agg(to_jsonb(x)::text,''|'' order by to_jsonb(x)::text),'''')) from public.%I x where %s',t.tablename,t.tablename,condition);
end loop; end $$;
select * from pg_temp.fixture_baseline();
rollback;`
writeFileSync(resolve(out, "baseline.sql"), fingerprintSQL)
const baseline = sql(fingerprintSQL, "baseline")
json("baseline-before.json", baseline)
const report = {
  project,
  tag,
  scope: "Authenticated HTTPS API integration; not browser E2E",
  tests: [],
  cleanup: false,
}
const clients = []
const { createClient } = createRequire(resolve(root, "apps/web/package.json"))(
  "@supabase/supabase-js",
)
const env = Object.fromEntries(
  readFileSync(resolve(root, "apps/web/.env.local"), "utf8")
    .split("\n")
    .filter((l) => /^[A-Z_]+=/.test(l))
    .map((l) => {
      const i = l.indexOf("=")
      return [l.slice(0, i), l.slice(i + 1).replace(/^['"]|['"]$/g, "")]
    }),
)
const url = env.VITE_SUPABASE_URL
assert.equal(new URL(url).hostname, `${project}.supabase.co`)
const key = env.VITE_SUPABASE_ANON_KEY ?? env.VITE_SUPABASE_PUBLISHABLE_KEY
assert(key, "No publishable key")
const fresh = () =>
  createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: {
      fetch: (u, options) => fetch(u, { ...options, signal: AbortSignal.timeout(20_000) }),
    },
  })
async function rows(c, table, filter = {}) {
  let query = c.from(table).select("*")
  for (const [k, v] of Object.entries(filter)) query = query.eq(k, v)
  const { data, error } = await query
  assert.equal(error, null, `${table}: ${error?.message}`)
  return data
}
async function rpc(c, name, args) {
  const r = await c.rpc(name, args)
  assert.equal(r.error, null, `${name}: ${r.error?.message}`)
  return r.data
}
async function rejectRpc(c, name, args, prefix) {
  const r = await c.rpc(name, args)
  assert(
    r.error?.message.startsWith(prefix),
    `${name}: expected ${prefix}, got ${r.error?.message ?? "success"}`,
  )
}
async function test(name, fn) {
  try {
    const detail = await fn()
    report.tests.push({ name, status: "PASS", ...(detail ? { detail } : {}) })
    console.log(`PASS ${name}`)
  } catch (e) {
    report.tests.push({ name, status: "FAIL", error: e.message })
    throw e
  } finally {
    json("hosted-api.json", report)
  }
}
const date = "2026-09-28T12:00:00.000Z"
const args = (org) => ({ p_org: org, p_idem: randomUUID(), p_fecha: date })
let kept = false
try {
  const setup = `begin; set local statement_timeout='20s'; set local lock_timeout='5s';
${users
  .map(
    (
      u,
    ) => `insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change) values('00000000-0000-0000-0000-000000000000',${q(u.id)},'authenticated','authenticated',${q(u.email)},extensions.crypt(${q(u.password)},extensions.gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','');
insert into profiles(id,full_name) values(${q(u.id)},${q(`QA r06 ${u.role}`)});`,
  )
  .join("\n")}
${orgs
  .map(
    (
      o,
      i,
    ) => `insert into organizations(id,name,slug,created_by) values(${q(o.id)},${q(`QA M/H r06 ${i === 0 ? "A" : "B"}`)},${q(o.slug)},${q(users[i === 0 ? 0 : 3].id)});
insert into organization_settings(organization_id) values(${q(o.id)});
insert into subscriptions(organization_id,plan_id,status) select ${q(o.id)},id,'activa' from plans where code='palenque';`,
  )
  .join("\n")}
${users.map((u) => `insert into organization_members(organization_id,user_id,role,status) values(${q(u.org)},${q(u.id)},${q(u.role)},'activo');`).join("\n")}
insert into resources(id,organization_id,kind,code,capacity,capacity_unit) values
(${q(oven)},${q(A)},'horno','QA Horno',10000,'kg'),(${q(tina)},${q(A)},'tina','QA Tina 1',1000,'L'),(${q(tina2)},${q(A)},'tina','QA Tina 2',1000,'L');
insert into species(id,organization_id,common_name) values(${q(species)},${q(A)},'QA especie');
insert into predios(id,organization_id,name) values(${q(predio)},${q(A)},'QA predio');
insert into suppliers(id,organization_id,name) values(${q(supplier)},${q(A)},'QA proveedor');
commit; select 2 as fixture_organizations;`
  json("setup.json", sql(setup, "setup"))
  writeFileSync(credentialsFile, JSON.stringify({ url, users, orgs }), { mode: 0o600 })
  for (const u of users) {
    const c = fresh()
    clients.push(c)
    await test(`auth-${u.role}-${u.org === A ? "a" : "b"}`, async () => {
      const { data, error } = await c.auth.signInWithPassword({
        email: u.email,
        password: u.password,
      })
      assert.equal(error, null, error?.message)
      assert.equal(data.user.id, u.id)
    })
  }
  const [admin, producer, operator, other] = clients
  const bLot = await rpc(other, "registrar_recepcion_maguey", { ...args(B), p_kg: 31 })
  for (const [index, c] of [admin, producer].entries()) {
    const role = users[index].role
    let lot1, lot2, run, cooked, direct
    await test(`${role}-recepcion-minima`, async () => {
      lot1 = await rpc(c, "registrar_recepcion_maguey", { ...args(A), p_kg: 100.125 })
      const [l] = await rows(c, "lots", { id: lot1 }),
        [r] = await rows(c, "maguey_receptions", { lot_id: lot1 }),
        [op] = await rows(c, "operations", { id: l.operation_id })
      assert.equal(l.initial_quantity, 100.125)
      assert.equal(l.unit, "kg")
      for (const k of ["species_id", "predio_id", "supplier_id", "pina_count", "quality_note"])
        assert.equal(r[k], null)
      assert.equal(op.recorded_by, users[index].id)
      assert.equal(new Date(op.occurred_at).toISOString(), date)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: lot1 }))[0].remaining_kg, 100.125)
      return { lot: lot1, kg: 100.125, author: op.recorded_by, date }
    })
    await test(`${role}-recepcion-opcionales`, async () => {
      lot2 = await rpc(c, "registrar_recepcion_maguey", {
        ...args(A),
        p_kg: 200,
        p_pinas: 42,
        p_especie: species,
        p_predio: predio,
        p_proveedor: supplier,
        p_folio: `QA-${role}`,
        p_nota: "Captura QA explícita",
      })
      const [r] = await rows(c, "maguey_receptions", { lot_id: lot2 })
      assert.equal(r.pina_count, 42)
      assert.equal(r.species_id, species)
      assert.equal(r.predio_id, predio)
      assert.equal(r.supplier_id, supplier)
      assert.equal(r.quality_note, "Captura QA explícita")
    })
    await test(`${role}-exceso-atomico`, async () => {
      const a = { ...args(A), p_horno: oven, p_lotes: [lot1, lot2], p_kilos: [10, 201] }
      await rejectRpc(c, "abrir_horneado", a, "SALDO_INSUFICIENTE:")
      assert.equal((await rows(c, "operations", { idempotency_key: a.p_idem })).length, 0)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: lot1 }))[0].remaining_kg, 100.125)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: lot2 }))[0].remaining_kg, 200)
    })
    await test(`${role}-apertura-dos-lotes`, async () => {
      run = await rpc(c, "abrir_horneado", {
        ...args(A),
        p_horno: oven,
        p_lotes: [lot1, lot2],
        p_kilos: [40.125, 60],
      })
      const inputs = await rows(c, "roasting_run_inputs", { run_id: run })
      assert.equal(inputs.length, 2)
      assert.equal(
        inputs.reduce((s, x) => s + x.quantity_kg, 0),
        100.125,
      )
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: lot1 }))[0].remaining_kg, 60)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: lot2 }))[0].remaining_kg, 140)
    })
    await test(`${role}-cierre-linaje`, async () => {
      cooked = await rpc(c, "cerrar_horneado", {
        ...args(A),
        p_fecha: "2026-09-28T14:00:00.000Z",
        p_horneado: run,
        p_kilos_cocidos: 80.25,
      })
      const [r] = await rows(c, "roasting_runs", { id: run }),
        [l] = await rows(c, "lots", { id: cooked }),
        lineage = await rows(c, "lot_lineage", { child_lot_id: cooked })
      assert.equal(r.status, "cerrada")
      assert.equal(r.output_lot_id, cooked)
      assert.equal(r.cooked_kg, 80.25)
      assert.equal(l.initial_quantity, 80.25)
      assert.equal(l.origin, "producido")
      assert.equal(lineage.length, 2)
      assert.deepEqual(
        lineage.map((x) => [x.parent_lot_id, x.quantity]).sort(),
        [
          [lot1, 40.125],
          [lot2, 60],
        ].sort(),
      )
    })
    await test(`${role}-cocido-sin-horneada`, async () => {
      direct = await rpc(c, "registrar_entrada", {
        ...args(A),
        p_material: "agave_cocido",
        p_recurso: null,
        p_cantidad: 50.5,
        p_origen: "carga_inicial",
      })
      const [l] = await rows(c, "lots", { id: direct })
      assert.equal(l.origin, "carga_inicial")
      assert.equal(l.history, "sin_historia")
      assert.equal(l.unit, "kg")
      assert.equal(l.initial_quantity, 50.5)
      assert.equal((await rows(c, "roasting_runs", { output_lot_id: direct })).length, 0)
      assert.equal((await rows(c, "lot_lineage", { child_lot_id: direct })).length, 0)
    })
    await test(`${role}-formulacion-real`, async () => {
      const target = index === 0 ? tina : tina2
      const f = await rpc(c, "registrar_formulacion", {
        ...args(A),
        p_molino: null,
        p_lotes_cocido: [cooked, direct],
        p_kilos: [20.25, 10.5],
        p_agua_l: 70,
        p_tinas: [target],
        p_litros: [100],
      })
      const inputs = await rows(c, "formulation_inputs", { formulation_id: f })
      assert.equal(inputs.length, 2)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: cooked }))[0].remaining_kg, 60)
      assert.equal((await rows(c, "solid_lot_balances", { lot_id: direct }))[0].remaining_kg, 40)
      const [cycle] = await rows(c, "fermentation_cycles", { formulation_id: f })
      assert.equal(cycle.tina_id, target)
      assert.equal(cycle.status, "fermentando")
      const [movement] = await rows(c, "liquid_movements", { lot_id: cycle.lot_id })
      assert.equal(movement.volume_l, 100)
      return { formulation: f, cooked, direct, tina: target }
    })
  }
  const operations = [
    ["registrar_recepcion_maguey", { p_kg: 1 }],
    ["abrir_horneado", { p_horno: oven, p_lotes: [bLot], p_kilos: [1] }],
    ["cerrar_horneado", { p_horneado: randomUUID(), p_kilos_cocidos: 1 }],
    ["registrar_entrada", { p_material: "agave_cocido", p_recurso: null, p_cantidad: 1 }],
    [
      "registrar_formulacion",
      {
        p_molino: null,
        p_lotes_cocido: [bLot],
        p_kilos: [1],
        p_agua_l: 1,
        p_tinas: [tina],
        p_litros: [1],
      },
    ],
  ]
  for (const [name, payload] of operations)
    await test(`operador-rechaza-${name}`, () =>
      rejectRpc(operator, name, { ...args(A), ...payload }, "NO_PERMITIDO:"))
  await test("rls-segundo-tenant-lectura", async () => {
    assert.equal((await rows(admin, "lots", { organization_id: B })).length, 0)
    assert.equal((await rows(other, "lots", { organization_id: A })).length, 0)
    assert.equal((await rows(operator, "lots", { organization_id: A })).length > 0, true)
  })
  for (const [name, payload] of operations)
    await test(`otro-tenant-rechaza-${name}`, () =>
      rejectRpc(other, name, { ...args(A), ...payload }, "NO_PERMITIDO:"))
  await test("lote-ajeno-rechazado-sin-consumo", () =>
    rejectRpc(
      admin,
      "abrir_horneado",
      { ...args(A), p_horno: oven, p_lotes: [bLot], p_kilos: [1] },
      "NO_PERMITIDO:",
    ))
  sql(
    `begin; update subscriptions set status='vencida' where organization_id=${q(A)}; commit; select true as fixture_read_only;`,
    "read-only",
  )
  for (const [name, payload] of operations)
    await test(`solo-lectura-rechaza-${name}`, () =>
      rejectRpc(admin, name, { ...args(A), ...payload }, "NO_PERMITIDO:"))
  await test("solo-lectura-conserva-lectura", async () =>
    assert((await rows(admin, "lots", { organization_id: A })).length > 0))
  sql(
    `begin; update subscriptions set status='activa' where organization_id=${q(A)}; commit; select true as fixture_writable;`,
    "restore-active",
  )
  await test("respuesta-perdida-postcommit-reintento-cliente-nuevo", async () => {
    const intent = { ...args(A), p_kg: 7.125 }
    const session = (await admin.auth.getSession()).data.session
    // Send real HTTP, consume a successful response, then intentionally discard it.
    const response = await fetch(`${url}/rest/v1/rpc/registrar_recepcion_maguey`, {
      method: "POST",
      headers: {
        apikey: key,
        Authorization: `Bearer ${session.access_token}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(intent),
      signal: AbortSignal.timeout(20000),
    })
    assert.equal(response.ok, true)
    await response.text()
    const next = fresh()
    clients.push(next)
    const login = await next.auth.signInWithPassword({
      email: users[0].email,
      password: users[0].password,
    })
    assert.equal(login.error, null)
    const result = await rpc(next, "registrar_recepcion_maguey", JSON.parse(JSON.stringify(intent)))
    const persisted = await rows(next, "operations", { idempotency_key: intent.p_idem })
    assert.equal(persisted.length, 1)
    assert.equal(persisted[0].result_lot_id, result)
    assert.equal(new Date(persisted[0].occurred_at).toISOString(), date)
    assert.equal((await rows(next, "lots", { id: result }))[0].initial_quantity, 7.125)
    return {
      idempotencyKey: intent.p_idem,
      operation: persisted[0].id,
      lot: result,
      kg: 7.125,
      date,
      limitation: "New API client, not browser reload/localStorage recovery",
    }
  })
  report.status = "PASS"
  if (process.argv.includes("--keep-for-ui")) {
    kept = true
    report.fixtureState = "AWAITING_UI_THEN_CLEANUP"
    console.log(`UI credentials are private at ${credentialsFile}`)
  }
} catch (e) {
  report.status = "FAIL"
  report.error = e.message
  process.exitCode = 1
  console.log(`FAIL: ${e.message}`)
} finally {
  for (const c of clients) {
    try {
      await c.auth.signOut()
    } catch {
      /* SQL revokes fixture sessions below. */
    }
  }
  if (!kept) {
    try {
      const remaining = sql(cleanup, "cleanup")
      json("cleanup.json", remaining)
      assert(remaining.every((x) => x.remaining === 0))
      report.cleanup = true
      if (existsSync(credentialsFile)) unlinkSync(credentialsFile)
    } catch (e) {
      report.cleanupError = e.message
      process.exitCode = 1
    }
    const after = sql(fingerprintSQL, "baseline-after")
    json("baseline-after.json", after)
    report.existingPublicDataUnchanged = JSON.stringify(after) === JSON.stringify(baseline)
    if (!report.existingPublicDataUnchanged) process.exitCode = 1
  }
  json("hosted-api.json", report)
  console.log(
    JSON.stringify({
      status: report.status,
      tests: report.tests.length,
      cleanup: report.cleanup,
      keptForUI: kept,
    }),
  )
}
