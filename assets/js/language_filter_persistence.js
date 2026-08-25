// Remembers the search page's "restrict to these languages" selection in
// this browser (per Pan.Search.query/1's language_ids filter), so picking
// e.g. Italian for one search carries over to the next one instead of
// resetting to "all my languages" on every fresh page load. There's no
// server-side session write available from a connected LiveView socket
// (that needs an HTTP response to set a cookie), so this rides localStorage
// instead - purely a per-browser convenience, not real account state.
const STORAGE_KEY = "pan_language_filter_ids";

export const LanguageFilterPersistence = {
  mounted() {
    const stored = localStorage.getItem(STORAGE_KEY);

    if (stored !== null) {
      try {
        const ids = JSON.parse(stored);
        if (Array.isArray(ids)) {
          this.pushEvent("restore-language-filter", { ids });
        }
      } catch (e) {
        // malformed/legacy value - ignore, keep the page's default selection
      }
    }

    this.handleEvent("persist-language-filter", ({ ids }) => {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(ids));
    });
  },
};
