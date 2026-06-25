// rabble-dev router — dev.joinrabble.world
// /chrysalis/*  → rabble-chrysalis-web (service binding, prefix stripped)
// /*            → rabble-world-dev     (service binding, pass-through)

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    // Redirect bare /chrysalis to /chrysalis/
    if (path === '/chrysalis') {
      return Response.redirect(url.origin + '/chrysalis/', 301);
    }

    if (path.startsWith('/chrysalis/')) {
      const stripped = path.slice('/chrysalis'.length); // keeps leading /
      const inner = new URL(request.url);
      inner.pathname = stripped;

      const resp = await env.CHRYSALIS.fetch(new Request(inner.toString(), {
        method: request.method,
        headers: request.headers,
        body: request.body ?? undefined,
        redirect: 'manual',
      }));

      // Rewrite any absolute-path redirects (e.g. /foo/ → /chrysalis/foo/)
      if (resp.status >= 300 && resp.status < 400) {
        const loc = resp.headers.get('Location');
        if (loc && loc.startsWith('/') && !loc.startsWith('/chrysalis')) {
          const headers = new Headers(resp.headers);
          headers.set('Location', '/chrysalis' + loc);
          return new Response(resp.body, { status: resp.status, headers });
        }
      }

      return resp;
    }

    // Everything else → World new-horizons
    return env.WORLD_DEV.fetch(request);
  },
};
