// EN / DE switch in the sidebar (Project #4). The choice goes into the
// "locale" cookie, which PanWeb.Locale reads on the next request, so the page
// is reloaded to render in the new language. Listening on the document needs
// no inline script (Content-Security-Policy) and survives LiveView re-renders.
const COOKIE_MAX_AGE = 60 * 60 * 24 * 365;

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-locale-choice]");

  if (button && !button.classList.contains("btn-active")) {
    const locale = encodeURIComponent(button.dataset.localeChoice);
    document.cookie = `locale=${locale}; path=/; max-age=${COOKIE_MAX_AGE}; SameSite=Lax`;
    window.location.reload();
  }
});
