// Two REAL Management API sessions against a disposable tenant. No dblink,
// database password, reset, or demo data. Cleanup is scoped to random IDs.
import { spawn } from "node:child_process"
import { randomUUID } from "node:crypto"
import { readFileSync, mkdirSync, writeFileSync } from "node:fs"
import { resolve } from "node:path"
import { fileURLToPath } from "node:url"

const root = fileURLToPath(new URL("../", import.meta.url))
if (
  readFileSync(resolve(root, "supabase/.temp/project-ref"), "utf8").trim() !==
  "ypgeiyorgktshgbzhgfh"
)
  throw Error("Proyecto incorrecto")
const org = randomUUID(),
  user = randomUUID(),
  source = randomUUID(),
  dest1 = randomUUID(),
  dest2 = randomUUID()
const tag = `qa-race-${randomUUID().slice(0, 8)}`
const folder = resolve(
  root,
  "docs/plan/evidence",
  `${new Date().toISOString().replaceAll(":", "-")}-concurrency`,
)
mkdirSync(folder, { recursive: true })
let sequence = 0
async function query(sql, name) {
  const file = resolve(folder, `${++sequence}-${name}.sql`)
  writeFileSync(file, sql)
  return new Promise((resolveQuery, reject) => {
    const child = spawn(
      "supabase",
      ["db", "query", "--linked", "--project-ref", "ypgeiyorgktshgbzhgfh", "--yes", "-f", file],
      { cwd: root, stdio: ["ignore", "pipe", "pipe"] },
    )
    let out = "",
      err = ""
    child.stdout.on("data", (s) => {
      out += s
    })
    child.stderr.on("data", (s) => {
      err += s
    })
    const timeout = setTimeout(() => child.kill("SIGTERM"), 90_000)
    child.on("error", (e) => {
      clearTimeout(timeout)
      reject(e)
    })
    child.on("close", (code) => {
      clearTimeout(timeout)
      try {
        if (code !== 0) throw Error(`${name}: CLI ${code}: ${err.slice(-1500)}`)
        const response = JSON.parse(out.slice(out.indexOf("{")))
        if (!Array.isArray(response.rows)) throw Error("Respuesta sin filas")
        writeFileSync(
          file.replace(/\.sql$/, ".json"),
          JSON.stringify(response.rows, null, 2) + "\n",
        )
        resolveQuery(response.rows)
      } catch (e) {
        reject(e)
      }
    })
  })
}
const report = { tag, org, user, estado: "FAIL", sesiones: [], observaciones: [], limpieza: false }
const cleanup = `begin;
do $$ begin
  if exists(select 1 from organizations where id='${org}' and slug <> '${tag}') then raise exception 'Identidad inesperada'; end if;
  if exists(select 1 from auth.users where id='${user}' and email <> '${tag}@example.invalid') then raise exception 'Usuario inesperado'; end if;
end $$;
delete from liquid_movements where organization_id='${org}';
delete from lot_lineage where organization_id='${org}';
delete from operation_warnings where organization_id='${org}';
delete from lots where organization_id='${org}';
delete from operations where organization_id='${org}';
delete from organizations where id='${org}' and slug='${tag}';
delete from auth.users where id='${user}' and email='${tag}@example.invalid';
commit;
select (select count(*) from organizations where id='${org}') + (select count(*) from auth.users where id='${user}') as restantes;`
// Save recovery instructions BEFORE creating any remote rows.
writeFileSync(resolve(folder, "cleanup.sql"), cleanup)
const attempts = []
try {
  await query(
    `begin;
insert into auth.users(id,aud,role,email) values('${user}','authenticated','authenticated','${tag}@example.invalid');
insert into profiles(id,full_name) values('${user}','QA concurrencia');
insert into organizations(id,name,slug,created_by) values('${org}','QA concurrencia','${tag}','${user}');
insert into organization_members(organization_id,user_id,role,status) values('${org}','${user}','admin','activo');
insert into organization_settings(organization_id) values('${org}');
insert into subscriptions(organization_id,plan_id,status) select '${org}',id,'gratis' from plans where code='gratis';
insert into resources(id,organization_id,kind,code,capacity_policy) values
('${source}','${org}','tanque','Origen','libre'),('${dest1}','${org}','tanque','Destino 1','libre'),('${dest2}','${org}','tanque','Destino 2','libre');
set local role authenticated;
set local request.jwt.claims='{"sub":"${user}","role":"authenticated"}';
select registrar_entrada('${org}',gen_random_uuid(),now(),'granel','${source}',1,47,p_folio=>'QA-ULTIMO-LITRO');
reset role;
commit;
select id from organizations where id='${org}';`,
    "setup",
  )
  const attempt = (name, dest, pause) =>
    query(
      `begin;
set local application_name='${tag}-${name}';
set local statement_timeout='40s';
create temporary table resultado(pid int, resultado text, inicio timestamptz, fin timestamptz);
do $$ declare v text := 'OK'; inicio timestamptz := clock_timestamp(); lote uuid;
begin
  select id into lote from lots where organization_id='${org}' and folio='QA-ULTIMO-LITRO';
  begin
    execute 'set local role authenticated';
    perform set_config('request.jwt.claims','{"sub":"${user}","role":"authenticated"}',true);
    perform transferir('${org}',gen_random_uuid(),now(),'${source}','${dest}',lote,1);
  exception when others then v := sqlerrm; end;
  execute 'reset role';
  insert into resultado values(pg_backend_pid(),v,inicio,clock_timestamp());
  if v='OK' then perform pg_sleep(${pause}); end if;
end $$;
commit;
select * from resultado;`,
      name,
    )
  attempts.push(attempt("first", dest1, 20))
  // Attach rejection handlers immediately while observing concurrent work.
  attempts[0].catch(() => {})
  let ready = false
  for (let i = 0; i < 5; i++) {
    const rows = await query(
      `select pid,application_name,wait_event_type,wait_event from pg_stat_activity where application_name='${tag}-first';`,
      "barrier",
    )
    report.observaciones.push(...rows)
    if (rows.some((r) => r.wait_event === "PgSleep")) {
      ready = true
      break
    }
  }
  if (!ready)
    throw Error("No se observó la primera sesión reteniendo locks; no certificar concurrencia")
  attempts.push(attempt("second", dest2, 0))
  attempts[1].catch(() => {})
  let overlap = []
  for (let i = 0; i < 5; i++) {
    overlap = await query(
      `select pid,application_name,wait_event_type,wait_event from pg_stat_activity where application_name in ('${tag}-first','${tag}-second');`,
      "overlap",
    )
    report.observaciones.push(...overlap)
    if (overlap.some((r) => r.application_name === `${tag}-second` && r.wait_event_type === "Lock"))
      break
  }
  report.sesiones = (await Promise.all(attempts)).flat()
  const balance = await query(
    `select resource_id,volume_l from resource_lot_balances where organization_id='${org}';`,
    "balance",
  )
  report.saldos = balance
  const waiting = overlap.some(
    (r) => r.application_name === `${tag}-second` && r.wait_event_type === "Lock",
  )
  const winner = report.sesiones.filter((r) => r.resultado === "OK").length === 1
  const loser =
    report.sesiones.filter((r) => r.resultado.startsWith("SALDO_INSUFICIENTE:")).length === 1
  const separate = new Set(report.sesiones.map((r) => r.pid)).size === 2
  if (
    !waiting ||
    !winner ||
    !loser ||
    !separate ||
    balance.length !== 1 ||
    Number(balance[0].volume_l) !== 1
  )
    throw Error("Criterio de concurrencia no satisfecho")
  report.estado = "PASS"
} catch (e) {
  report.error = e.message
} finally {
  report.resultadosIntentos = (await Promise.allSettled(attempts)).map((r) =>
    r.status === "fulfilled" ? r.value : { error: r.reason.message },
  )
  try {
    report.limpieza = Number((await query(cleanup, "cleanup"))[0].restantes) === 0
  } catch (e) {
    report.errorLimpieza = e.message
  }
  if (!report.limpieza) report.estado = "FAIL"
  writeFileSync(resolve(folder, "concurrency.json"), JSON.stringify(report, null, 2) + "\n")
}
console.log(JSON.stringify(report, null, 2))
console.log(`Evidencia: ${folder}`)
process.exitCode = report.estado === "PASS" ? 0 : 1
