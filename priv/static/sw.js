// Minimal service worker — required by some browsers' install criteria for
// "Add to Home Screen"/desktop installability alongside the web manifest
// (see priv/static/config/site.webmanifest). Intentionally does no caching
// yet — that's a separate, later step (see backlog.md).
self.addEventListener("install", () => {
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener("fetch", () => {
  // no-op: every request still goes straight to the network for now
});
