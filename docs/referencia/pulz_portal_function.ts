/**
 * PULZ · Portal por empresa
 * Ruta en el repo: apps/web/functions/e/[slug]/[[path]].ts  (Cloudflare Pages Functions)
 *
 * Qué resuelve: que pulz.mx/e/istmeno se sienta como el portal PROPIO del
 * palenque desde el primer byte, no después de que cargue el JavaScript.
 *
 *   - El HTML llega ya con el nombre, color e icono de la empresa. Así la
 *     pestaña, la vista previa en WhatsApp y el «Agregar a inicio» de iOS
 *     dicen «Palenque Istmeño», no «PULZ». (Cambiar el manifiesto desde el
 *     navegador, después de cargar, no funciona igual en todos los teléfonos
 *     y en iOS el nombre del icono se quedaba con el de la plataforma.)
 *   - /e/<slug>/manifest.webmanifest es propio de cada empresa: dos palenques
 *     instalados en el mismo teléfono son dos apps, cada una con su nombre.
 *   - Un slug viejo redirige al nuevo con 301: los iconos ya instalados y los
 *     enlaces que circulan por WhatsApp siguen sirviendo.
 *   - Empresa inexistente o cancelada: el mismo 404 genérico, sin pistas.
 *
 * Nada de esto guarda sesión ni datos: sólo pinta la puerta. La seguridad
 * sigue en Postgres (RLS). Si esta función falla, la app carga genérica y
 * funciona igual: es una mejora, no una dependencia.
 */

interface Env {
  SUPABASE_URL: string
  SUPABASE_ANON_KEY: string
  ASSETS: Fetcher
}

interface Portal {
  organization_id: string
  slug: string
  name: string
  logo_path: string | null
  brand_color: string | null
  welcome_message: string | null
  read_only: boolean
  redirect_to: string | null
}

const COLOR_PULZ = '#173F87'
const CACHE_SEGUNDOS = 300

/** Nombre corto bajo el icono del teléfono (~12 caracteres caben). */
const corto = (nombre: string, tope = 12) =>
  nombre.length <= tope ? nombre : `${nombre.slice(0, tope - 1).trimEnd()}…`

async function leerPortal(env: Env, slug: string, ctx: ExecutionContext): Promise<Portal | null> {
  const cache = caches.default
  const clave = new Request(`https://cache.pulz.internal/portal/${slug}`)
  const guardado = await cache.match(clave)
  if (guardado) {
    const filas = (await guardado.json()) as Portal[]
    return filas[0] ?? null
  }
  const res = await fetch(`${env.SUPABASE_URL}/rest/v1/rpc/portal_branding`, {
    method: 'POST',
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ p_slug: slug }),
  })
  if (!res.ok) throw new Error(`portal_branding ${res.status}`)
  const filas = (await res.json()) as Portal[]
  // También se cachea el «no existe», para que tantear slugs no golpee la base
  ctx.waitUntil(cache.put(clave, new Response(JSON.stringify(filas), {
    headers: { 'cache-control': `max-age=${CACHE_SEGUNDOS}` },
  })))
  return filas[0] ?? null
}

function manifiesto(p: Portal, env: Env) {
  const base = `/e/${p.slug}/`
  const iconos = [
    { src: '/icons/pwa-192x192.png', sizes: '192x192', type: 'image/png', purpose: 'any' },
    { src: '/icons/pwa-512x512.png', sizes: '512x512', type: 'image/png', purpose: 'any' },
    { src: '/icons/maskable-512x512.png', sizes: '512x512', type: 'image/png', purpose: 'maskable' },
  ]
  if (p.logo_path) {
    iconos.unshift({
      src: `${env.SUPABASE_URL}/storage/v1/object/public/branding/${p.logo_path}`,
      sizes: '512x512', type: 'image/png', purpose: 'any',
    })
  }
  return {
    id: base, scope: base, start_url: base,
    name: `${p.name} · PULZ`,
    short_name: corto(p.name),
    description: `Producción y trazabilidad de ${p.name}.`,
    display: 'standalone',
    theme_color: p.brand_color ?? COLOR_PULZ,
    background_color: '#F7F5F2',
    lang: 'es-MX',
    icons: iconos,
  }
}

export const onRequestGet: PagesFunction<Env, 'slug' | 'path'> = async (ctx) => {
  const url = new URL(ctx.request.url)
  const slug = String(ctx.params.slug).toLowerCase()
  const resto = ([] as string[]).concat(ctx.params.path ?? []).join('/')

  let portal: Portal | null = null
  try {
    portal = await leerPortal(ctx.env, slug, ctx)
  } catch {
    // Supabase no respondió: se sirve la app genérica y el router decide.
    return ctx.env.ASSETS.fetch(new URL('/index.html', url))
  }

  if (!portal) {
    const html = await ctx.env.ASSETS.fetch(new URL('/index.html', url))
    return new Response(html.body, { status: 404, headers: html.headers })
  }

  if (portal.redirect_to) {
    const nueva = url.pathname.replace(`/e/${slug}`, `/e/${portal.redirect_to}`)
    return Response.redirect(new URL(nueva + url.search, url).toString(), 301)
  }

  if (resto === 'manifest.webmanifest') {
    return new Response(JSON.stringify(manifiesto(portal, ctx.env)), {
      headers: {
        'content-type': 'application/manifest+json; charset=utf-8',
        'cache-control': `public, max-age=${CACHE_SEGUNDOS}`,
      },
    })
  }

  const index = await ctx.env.ASSETS.fetch(new URL('/index.html', url))
  const color = portal.brand_color ?? COLOR_PULZ
  const titulo = `${portal.name} · PULZ`
  const logo = portal.logo_path
    ? `${ctx.env.SUPABASE_URL}/storage/v1/object/public/branding/${portal.logo_path}`
    : null

  // setAttribute y setInnerContent escapan el texto: un nombre comercial con
  // comillas o «<» no puede inyectar HTML.
  const marca = new HTMLRewriter()
    .on('title', { element: (e) => { e.setInnerContent(titulo) } })
    .on('meta[name="apple-mobile-web-app-title"]', { element: (e) => { e.setAttribute('content', corto(portal!.name)) } })
    .on('meta[name="application-name"]', { element: (e) => { e.setAttribute('content', corto(portal!.name)) } })
    .on('meta[name="theme-color"]', { element: (e) => { e.setAttribute('content', color) } })
    .on('meta[property="og:title"]', { element: (e) => { e.setAttribute('content', titulo) } })
    .on('meta[property="og:description"]', {
      element: (e) => { e.setAttribute('content', portal!.welcome_message ?? `Portal de ${portal!.name}`) },
    })
    .on('link[rel="manifest"]', { element: (e) => { e.setAttribute('href', `/e/${portal!.slug}/manifest.webmanifest`) } })
    .on('link[rel="apple-touch-icon"]', { element: (e) => { if (logo) e.setAttribute('href', logo) } })
    .on('html', { element: (e) => { e.setAttribute('data-portal', portal!.slug) } })

  const res = marca.transform(index)
  const headers = new Headers(res.headers)
  headers.set('cache-control', 'no-cache')           // la marca puede cambiar
  headers.set('x-robots-tag', 'noindex')             // los portales no se indexan
  return new Response(res.body, { status: 200, headers })
}

/*
 * index.html necesita estas etiquetas con valores genéricos, para que la
 * función tenga qué reescribir (y para que sin función todo siga válido):
 *
 *   <title>PULZ</title>
 *   <meta name="application-name" content="PULZ">
 *   <meta name="apple-mobile-web-app-title" content="PULZ">
 *   <meta name="theme-color" content="#173F87">
 *   <meta property="og:title" content="PULZ">
 *   <meta property="og:description" content="Producción y trazabilidad de mezcal">
 *   <link rel="manifest" href="/manifest.webmanifest">
 *   <link rel="apple-touch-icon" href="/icons/apple-touch-icon-180x180.png">
 *
 * Service worker: al registrar la PWA desde un portal, el navigateFallback
 * del SW sirve el index.html cacheado (genérico). La primera carga, que es la
 * que el teléfono usa para instalar, sí pasa por esta función; después, la
 * app fija document.title desde el portal que ya conoce.
 */
