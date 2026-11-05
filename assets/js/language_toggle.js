// EN / DE switch in the sidebar (Project #4). POST /locale sets the "locale"
// cookie and, for logged-in users, their setting (PanWeb.LocaleController);
// then the page is reloaded to render in the new language. Listening on the
// document needs no inline script (Content-Security-Policy) and survives
// LiveView re-renders.
document.addEventListener("click", async (event) => {
  const button = event.target.closest("[data-locale-choice]");

  if (button && !button.classList.contains("btn-active")) {
    const csrfToken = document
      .querySelector("meta[name='csrf-token']")
      .getAttribute("content");

    const body = new URLSearchParams({ locale: button.dataset.localeChoice });

    const response = await fetch("/locale", {
      method: "POST",
      headers: { "x-csrf-token": csrfToken },
      body: body,
    });

    if (response.ok) {
      window.location.reload();
    }
  }
});
