// Service worker: makes repeat loads fast and shows a friendly page when the
// network is gone. LiveView pages need a live WebSocket, so nothing here tries
// to make pages themselves work offline (see backlog.md).
//
// - /assets/* and /fonts/* with a digest in the file name (name-<32 hex>.ext):
//   cache-first, since a digested URL never changes its content. Undigested
//   URLs (as in dev) are not touched, so development never sees stale files.
// - /images/*: stale-while-revalidate (file names are not digested)
// - page navigations: network-first, /offline.html when the network fails
// - everything else (non-GET, cross-origin, Range requests such as audio,
//   /live WebSocket long-poll fallback) goes straight to the network
//
// Bump VERSION to drop all old caches on the next activation.
const VERSION = "v1";
const STATIC_CACHE = `pan-static-${VERSION}`;
const IMAGE_CACHE = `pan-images-${VERSION}`;
const OFFLINE_URL = "/offline.html";
const DIGESTED = /-[0-9a-f]{32}\.[a-z0-9]+$/;

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(STATIC_CACHE)
      .then((cache) => cache.add(OFFLINE_URL))
      .then(() => self.skipWaiting())
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((names) =>
        Promise.all(
          names
            .filter((name) => name !== STATIC_CACHE && name !== IMAGE_CACHE)
            .map((name) => caches.delete(name))
        )
      )
      .then(() => self.clients.claim())
  );
});

async function cacheFirst(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  if (cached) return cached;

  const response = await fetch(request);
  if (response.ok) cache.put(request, response.clone());
  return response;
}

async function staleWhileRevalidate(request, cacheName) {
  const cache = await caches.open(cacheName);
  const cached = await cache.match(request);
  const refresh = fetch(request)
    .then((response) => {
      if (response.ok) cache.put(request, response.clone());
      return response;
    })
    .catch(() => cached);

  return cached || refresh;
}

async function networkFirstPage(request) {
  try {
    return await fetch(request);
  } catch (_error) {
    return (await caches.match(OFFLINE_URL)) || Response.error();
  }
}

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const url = new URL(request.url);

  if (
    request.method !== "GET" ||
    url.origin !== self.location.origin ||
    request.headers.has("range")
  ) {
    return;
  }

  if (request.mode === "navigate") {
    event.respondWith(networkFirstPage(request));
  } else if (
    (url.pathname.startsWith("/assets/") || url.pathname.startsWith("/fonts/")) &&
    DIGESTED.test(url.pathname)
  ) {
    event.respondWith(cacheFirst(request, STATIC_CACHE));
  } else if (url.pathname.startsWith("/images/")) {
    event.respondWith(staleWhileRevalidate(request, IMAGE_CACHE));
  }
});
