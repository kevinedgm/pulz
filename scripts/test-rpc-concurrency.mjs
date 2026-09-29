// Concurrencia REAL (PULZ_MAESTRO.md §16 Fase 2, tarea 12): sesiones
// distintas por el camino de producción (PostgREST + Auth), no por la
// Management API. Tenant desechable `qa-race-<8hex>` con dos usuarios admin,
// creado por SQL (CLI) y borrado por sus UUID exactos al final; nunca la
// demo, nunca reset, nunca DDL. Cuatro carreras:
//   1. último litro: dos `transferir` simultáneas del mismo litro desde dos
//      sesiones → exactamente una pasa y la otra SALDO_INSUFICIENTE (×3 rondas)
//   2. sobre-demanda: 3 L y 10 `transferir` de 1 L a la vez → exactamente 3 OK
//   3. misma clave de idempotencia a la vez → una sola operación, saldo movido una vez
//   4. escrituras independientes a la vez (dos tanques) → las dos pasan, sin deadlock
// Nunca se imprime SQL, stderr del CLI ni contraseñas.
//   node scripts/test-rpc-concurrency.mjs            (corre y limpia)
//   node scripts/test-rpc-concurrency.mjs --cleanup  (rehace la limpieza del manifest)
import { spawnSync } from "node:child_process"
import { randomBytes, randomUUID, createHash } from "node:crypto"
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, unlinkSync } from "node:fs"
import { tmpdir } from "node:os"
import { resolve } from "node:path"
import { createRequire } from "node:module"
import assert from "node:assert/strict"

const root = resolve(import.meta.dirname, "..")
const project = "ypgeiyorgktshgbzhgfh"
assert.equal(readFileSync(resolve(root, "supabase/.temp/project-ref"), "utf8").trim(), project)
const out = resolve(
  root,
  "docs/plan/evidence",
  `${new Date().toISOString().replaceAll(":", "-")}-concurrency-postgrest`,
)
mkdirSync(out, { recursive: true })
const json = (name, value) =>
  writeFileSync(resolve(out, name), JSON.stringify(value, null, 2) + "\n")
const q = (v) => `'${String(v).replaceAll("'", "''")}'`
const temp = mkdtempSync(resolve(tmpdir(), "pulz-race-"))
function sql(statement, name) {
  const file = resolve(temp, `${name}.sql`)
  writeFileSync(file, statement, { mode: 0o600 })
  try {
    const r = spawnSync(
      "supabase",
      ["db", "query", "--linked", "--project-ref", project, "-f", file, "--output", "json"],
      { cwd: root, encoding: "utf8", timeout: 90_000, maxBuffer: 4_000_000 },
    )
    // Nunca volcar SQL ni stderr: el setup lleva credenciales efímeras.
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
  const dir = process.argv[process.argv.indexOf("--cleanup") + 1]
  assert(dir, "Falta la carpeta de evidencia")
  const m = JSON.parse(readFileSync(resolve(dir, "manifest.json"), "utf8"))
  assert.equal(m.project, project)
  assert.match(m.tag, /^qa-race-[0-9a-f]{8}$/)
  const cleanupSql = readFileSync(resolve(dir, "cleanup.sql"), "utf8")
  assert.equal(createHash("sha256").update(cleanupSql).digest("hex"), m.cleanupSha256)
  writeFileSync(resolve(dir, "cleanup.json"), JSON.stringify(sql(cleanupSql, "cleanup"), null, 2))
  console.log("Limpieza acotada repetida; revisa cleanup.json")
  process.exit(0)
}

// ---------- fixtures desechables ----------
const tag = `qa-race-${randomUUID().slice(0, 8)}`
const org = randomUUID()
const users = ["a", "b"].map((s) => ({
  id: randomUUID(),
  email: `${tag}-${s}@example.invalid`,
  password: randomBytes(24).toString("base64url"),
}))
const [origen, dest1, dest2, dest3] = [randomUUID(), randomUUID(), randomUUID(), randomUUID()]
const userList = users.map((u) => q(u.id)).join(",")
const scopedTables = ["liquid_movements", "lot_lineage", "operation_warnings", "lots", "operations"]
const cleanup = `begin;
set local statement_timeout='20s';
set local lock_timeout='5s';
do $$ begin
if exists(select 1 from organizations where id=${q(org)} and slug<>${q(tag)}) then raise exception 'Fixture org identity mismatch'; end if;
${users.map((u) => `if exists(select 1 from auth.users where id=${q(u.id)} and email<>${q(u.email)}) then raise exception 'Fixture user identity mismatch'; end if;`).join("\n")}
end $$;
delete from auth.refresh_tokens where user_id in (${userList});
delete from auth.sessions where user_id in (${userList});
${scopedTables.map((t) => `delete from public.${t} where organization_id=${q(org)};`).join("\n")}
delete from organizations where id=${q(org)};
delete from auth.users where id in (${userList});
commit;
select 'organizations' as entity,count(*)::int as remaining from organizations where id=${q(org)}
union all select 'users',count(*)::int from auth.users where id in (${userList})
union all select 'profiles',count(*)::int from profiles where id in (${userList})
union all select 'resources',count(*)::int from resources where organization_id=${q(org)}
${scopedTables.map((t) => `union all select '${t}',count(*)::int from public.${t} where organization_id=${q(org)}`).join("\n")};`
writeFileSync(resolve(out, "cleanup.sql"), cleanup)
json("manifest.json", {
  project,
  tag,
  org,
  users: users.map((u) => ({ id: u.id, email: u.email })),
  resources: { origen, dest1, dest2, dest3 },
  cleanupSha256: createHash("sha256").update(cleanup).digest("hex"),
  note: "Tenant desechable por PostgREST; limpieza por UUID exactos. Sin demo, reset ni DDL.",
})

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
const fresh = () =>
  createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: { fetch: (u, o) => fetch(u, { ...o, signal: AbortSignal.timeout(30_000) }) },
  })

const report = {
  fecha: new Date().toISOString(),
  tag,
  estado: "FAIL",
  carreras: [],
  limpieza: false,
}
const checks = []
const ok = (c, m) => checks.push({ ok: Boolean(c), m })
const ahora = () => new Date().toISOString()
// Una llamada cronometrada: qué devolvió y cuándo estuvo en vuelo
async function llamada(c, nombre, args) {
  const inicio = ahora()
  const r = await c.rpc(nombre, args)
  return {
    inicio,
    fin: ahora(),
    ok: !r.error,
    data: r.data ?? null,
    error: r.error?.message ?? null,
  }
}
const solapan = (a, b) => a.inicio < b.fin && b.inicio < a.fin
async function saldos(c) {
  const { data, error } = await c
    .from("resource_lot_balances")
    .select("resource_id,lot_id,volume_l")
    .eq("organization_id", org)
  assert.equal(error, null, error?.message)
  return data
}
async function litrosDe(c, recurso) {
  return (await saldos(c))
    .filter((s) => s.resource_id === recurso)
    .reduce((a, s) => a + Number(s.volume_l), 0)
}
async function loteVivo(c, recurso) {
  const s = (await saldos(c)).find((x) => x.resource_id === recurso && Number(x.volume_l) > 0)
  assert(s, "el origen no tiene lote con saldo")
  return s.lot_id
}
const entrada = (c, recurso, litros) =>
  llamada(c, "registrar_entrada", {
    p_org: org,
    p_idem: randomUUID(),
    p_fecha: ahora(),
    p_material: "granel",
    p_recurso: recurso,
    p_cantidad: litros,
    p_abv: 47,
    p_clase: "mezcal",
    p_origen: "carga_inicial",
  })
const transferir = (c, lote, destino, litros = 1, idem = randomUUID()) =>
  llamada(c, "transferir", {
    p_org: org,
    p_idem: idem,
    p_fecha: ahora(),
    p_origen: origen,
    p_destino: destino,
    p_lote: lote,
    p_litros: litros,
  })

try {
  sql(
    `begin; set local statement_timeout='20s'; set local lock_timeout='5s';
${users
  .map(
    (
      u,
    ) => `insert into auth.users(instance_id,id,aud,role,email,encrypted_password,email_confirmed_at,raw_app_meta_data,raw_user_meta_data,created_at,updated_at,confirmation_token,recovery_token,email_change_token_new,email_change) values('00000000-0000-0000-0000-000000000000',${q(u.id)},'authenticated','authenticated',${q(u.email)},extensions.crypt(${q(u.password)},extensions.gen_salt('bf')),now(),'{"provider":"email","providers":["email"]}','{}',now(),now(),'','','','');
insert into profiles(id,full_name) values(${q(u.id)},${q(`QA carrera ${u.email.slice(-17, -16)}`)});`,
  )
  .join("\n")}
insert into organizations(id,name,slug,created_by) values(${q(org)},'QA concurrencia',${q(tag)},${q(users[0].id)});
insert into organization_settings(organization_id) values(${q(org)});
insert into subscriptions(organization_id,plan_id,status) select ${q(org)},id,'activa' from plans where code='palenque';
${users.map((u) => `insert into organization_members(organization_id,user_id,role,status) values(${q(org)},${q(u.id)},'admin','activo');`).join("\n")}
insert into resources(id,organization_id,kind,code,capacity_policy) values
(${q(origen)},${q(org)},'tanque','QA Origen','libre'),(${q(dest1)},${q(org)},'tanque','QA Destino 1','libre'),(${q(dest2)},${q(org)},'tanque','QA Destino 2','libre'),(${q(dest3)},${q(org)},'tanque','QA Destino 3','libre');
commit; select 1 as fixture_organizations;`,
    "setup",
  )
  const [A, B] = [fresh(), fresh()]
  for (const [i, c] of [A, B].entries()) {
    const { data, error } = await c.auth.signInWithPassword({
      email: users[i].email,
      password: users[i].password,
    })
    assert.equal(error, null, error?.message)
    assert.equal(data.user.id, users[i].id)
  }
  report.sesiones = "dos usuarios admin con sesión propia (Auth password grant) sobre PostgREST"

  // 1. Último litro, tres rondas
  for (let ronda = 1; ronda <= 3; ronda++) {
    const e = await entrada(A, origen, 1)
    assert(e.ok, `entrada ronda ${ronda}: ${e.error}`)
    const lote = await loteVivo(A, origen)
    const [ra, rb] = await Promise.all([transferir(A, lote, dest1), transferir(B, lote, dest2)])
    const ganadores = [ra, rb].filter((r) => r.ok).length
    const perdedores = [ra, rb].filter((r) => r.error?.startsWith("SALDO_INSUFICIENTE")).length
    const restante = await litrosDe(A, origen)
    const c = {
      carrera: "ultimo-litro",
      ronda,
      A: ra,
      B: rb,
      solapan: solapan(ra, rb),
      origenRestante: restante,
    }
    report.carreras.push(c)
    ok(
      ganadores === 1 && perdedores === 1,
      `último litro ronda ${ronda}: exactamente una pasa y la otra SALDO_INSUFICIENTE (${ganadores}/${perdedores})`,
    )
    ok(restante === 0, `último litro ronda ${ronda}: el origen queda en 0 L (${restante})`)
    ok(c.solapan, `último litro ronda ${ronda}: las dos peticiones estuvieron en vuelo a la vez`)
  }

  // 2. Sobre-demanda: 3 L y 10 transferencias de 1 L a la vez
  {
    const e = await entrada(A, origen, 3)
    assert(e.ok, e.error)
    const lote = await loteVivo(A, origen)
    const destinos = [dest1, dest2, dest3]
    const res = await Promise.all(
      Array.from({ length: 10 }, (_, i) => transferir(i % 2 ? A : B, lote, destinos[i % 3])),
    )
    const okN = res.filter((r) => r.ok).length
    const saldoN = res.filter((r) => r.error?.startsWith("SALDO_INSUFICIENTE")).length
    const otros = res
      .filter((r) => !r.ok && !r.error?.startsWith("SALDO_INSUFICIENTE"))
      .map((r) => r.error)
    const restante = await litrosDe(A, origen)
    report.carreras.push({
      carrera: "sobre-demanda",
      pedidas: 10,
      litros: 3,
      ok: okN,
      saldoInsuficiente: saldoN,
      otros,
      origenRestante: restante,
      resultados: res,
    })
    ok(
      okN === 3 && saldoN === 7 && otros.length === 0,
      `sobre-demanda: 3 OK y 7 SALDO_INSUFICIENTE de 10 (${okN}/${saldoN}, otros: ${otros.join(" | ")})`,
    )
    ok(restante === 0, `sobre-demanda: el origen queda en 0 L (${restante})`)
  }

  // 3. Misma clave de idempotencia a la vez
  {
    const e = await entrada(A, origen, 5)
    assert(e.ok, e.error)
    const lote = await loteVivo(A, origen)
    const idem = randomUUID()
    const [ra, rb] = await Promise.all([
      transferir(A, lote, dest1, 1, idem),
      transferir(A, lote, dest1, 1, idem),
    ])
    const { data: ops } = await A.from("operations")
      .select("id")
      .eq("organization_id", org)
      .eq("idempotency_key", idem)
    const restante = await litrosDe(A, origen)
    report.carreras.push({
      carrera: "idempotencia-simultanea",
      idem,
      A: ra,
      B: rb,
      operaciones: ops?.length ?? null,
      origenRestante: restante,
    })
    ok(
      ops?.length === 1,
      `idempotencia simultánea: una sola operación con la clave (${ops?.length})`,
    )
    ok(
      restante === 4,
      `idempotencia simultánea: el saldo se movió una sola vez (quedan ${restante} L de 5)`,
    )
    ok(ra.ok || rb.ok, "idempotencia simultánea: al menos una llamada devolvió la operación")
    // Hallazgo informativo: qué recibe la segunda llamada cuando pierde la carrera
    report.idempotenciaSegundaLlamada = [ra, rb].filter((r) => !r.ok).map((r) => r.error)
  }

  // 4. Escrituras independientes a la vez (sin deadlock)
  {
    const [ra, rb] = await Promise.all([entrada(A, dest2, 2), entrada(B, dest3, 2)])
    report.carreras.push({ carrera: "independientes", A: ra, B: rb, solapan: solapan(ra, rb) })
    ok(
      ra.ok && rb.ok,
      `independientes: las dos entradas pasan (${ra.error ?? "ok"} / ${rb.error ?? "ok"})`,
    )
  }

  report.saldosFinales = await saldos(A)
  const fallos = checks.filter((c) => !c.ok).map((c) => c.m)
  report.checks = checks
  report.fallos = fallos
  report.estado = fallos.length ? "FAIL" : "PASS"
} catch (e) {
  report.error = e.message
  report.checks = checks
  report.estado = "FAIL"
} finally {
  try {
    const remaining = sql(cleanup, "cleanup")
    json("cleanup.json", remaining)
    report.limpieza = remaining.every((r) => Number(r.remaining) === 0)
  } catch (e) {
    report.errorLimpieza = e.message
  }
  if (!report.limpieza) report.estado = "FAIL"
  json("concurrency.json", report)
}
console.log(
  JSON.stringify(
    {
      estado: report.estado,
      checks: report.checks?.length,
      fallos: report.fallos ?? report.error,
      limpieza: report.limpieza,
      idempotenciaSegundaLlamada: report.idempotenciaSegundaLlamada,
      evidencia: out,
    },
    null,
    2,
  ),
)
process.exitCode = report.estado === "PASS" ? 0 : 1
