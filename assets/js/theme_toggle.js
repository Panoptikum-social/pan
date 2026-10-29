// Latte / System / Mocha switch in the sidebar (DESIGN.md, Themes). Without a
// data-theme on <html> the CSS follows prefers-color-scheme (latte light,
// mocha dark); choosing Latte or Mocha sets it. The choice is a per-browser
// convenience in localStorage, applied before the first paint by the script
// in _head.html.heex. Listening on the document needs no inline script
// (Content-Security-Policy) and survives LiveView re-renders.
const STORAGE_KEY = "pan_theme";
const DEFAULT_CHOICE = "system";

let choice = DEFAULT_CHOICE;
try {
  choice = localStorage.getItem(STORAGE_KEY) || DEFAULT_CHOICE;
} catch (e) {
  // storage blocked - stay with the default
}

function applyTheme() {
  if (choice === "latte" || choice === "mocha") {
    document.documentElement.setAttribute("data-theme", choice);
  } else {
    document.documentElement.removeAttribute("data-theme");
  }

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

window.addEventListener("phx:page-loading-stop", applyTheme);
document.addEventListener("DOMContentLoaded", applyTheme);
