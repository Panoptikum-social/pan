// Latte / Mocha / System switch for elements marked with
// data-theme-toggle-scope (the admin and moderation layouts' <main>, see
// backlog.md #436).
// The choice is a per-browser convenience in localStorage. Listening on the
// document and re-applying after live navigation keeps this working across
// LiveView re-renders and needs no inline script (Content-Security-Policy).
const STORAGE_KEY = "pan_theme";
const DEFAULT_CHOICE = "latte";
const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

let choice = DEFAULT_CHOICE;
try {
  choice = localStorage.getItem(STORAGE_KEY) || DEFAULT_CHOICE;
} catch (e) {
  // storage blocked - stay with the default
}

function applyTheme() {
  const theme =
    choice === "system" ? (darkQuery.matches ? "mocha" : "latte") : choice;

  document.querySelectorAll("[data-theme-toggle-scope]").forEach((scope) => {
    scope.setAttribute("data-theme", theme);
  });

  document.querySelectorAll("[data-theme-choice]").forEach((button) => {
    const active = button.dataset.themeChoice === choice;
    button.classList.toggle("btn-active", active);
    button.setAttribute("aria-pressed", active);
  });
}

document.addEventListener("click", (event) => {
  const button = event.target.closest("[data-theme-choice]");

  if (button) {
    choice = button.dataset.themeChoice;
    try {
      localStorage.setItem(STORAGE_KEY, choice);
    } catch (e) {
      // storage blocked - the choice holds until the next page load
    }
    applyTheme();
  }
});

darkQuery.addEventListener("change", applyTheme);
window.addEventListener("phx:page-loading-stop", applyTheme);
document.addEventListener("DOMContentLoaded", applyTheme);
