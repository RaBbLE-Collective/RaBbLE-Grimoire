// rabble-dev router — dev.joinrabble.world
// /*  → rabble-world-dev (service binding, pass-through)
//
// S249: the /chrysalis/* passage was removed (Mark, D4). The reliquary lives on its own
// channel at chrysalis.joinrabble.world; dev and prod no longer mount it under a path.
// /chrysalis now 301s to that channel so old links still land somewhere.

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const path = url.pathname;

    if (path === '/chrysalis' || path.startsWith('/chrysalis/')) {
      const rest = path.slice('/chrysalis'.length) || '/';
      return Response.redirect('https://chrysalis.joinrabble.world' + rest + url.search, 301);
    }

    return env.WORLD_DEV.fetch(request);
  },
};
