// The web player runs in an iframe, so our CSS variables don't reach it: its
// theme tokens are Catppuccin values per theme (DESIGN.md), the play button as
// the main action in primary blue, the show title in the podcast color (Latte
// peach darkened to 4.5:1). Theme changes (toggle or OS setting) reach a
// running player through PLAYER_SET_THEME, so playback goes on.
const TOKENS = {
  latte: {
    brand: "#be4601",
    brandDark: "#1e66f5",
    brandDarkest: "#4c4f69",
    brandLightest: "#eff1f5",
    shadeDark: "#6c6f85",
    shadeBase: "#8c8fa1",
    contrast: "#4c4f69",
    alt: "#ffffff",
  },
  mocha: {
    brand: "#fab387",
    brandDark: "#89b4fa",
    brandDarkest: "#cdd6f4",
    brandLightest: "#1e1e2e",
    shadeDark: "#a6adc8",
    shadeBase: "#7f849c",
    contrast: "#cdd6f4",
    alt: "#1e1e2e",
  },
};

const darkQuery = window.matchMedia("(prefers-color-scheme: dark)");

function currentTheme() {
  const chosen = document.documentElement.getAttribute("data-theme");
  if (chosen === "latte" || chosen === "mocha") return chosen;
  return darkQuery.matches ? "mocha" : "latte";
}

const themeFor = (name) => ({ tokens: TOKENS[name] });

let PodlovePlayer = {
  mounted() {
    this.pushEventTo(this.el, "read-config", {}, ({ episode, config }, ref) => {
      this.theme = currentTheme();

      window
        .podlovePlayer("#podlove-player", episode, { ...config, theme: themeFor(this.theme) })
        .then((store) => {
          this.store = store;
          registerExternalEvents("podlove-player")(store);
        });
    });

    this.retheme = () => {
      const theme = currentTheme();
      if (!this.store || theme === this.theme) return;
      this.theme = theme;
      this.store.dispatch({ type: "PLAYER_SET_THEME", payload: themeFor(theme) });
    };

    this.observer = new MutationObserver(this.retheme);
    this.observer.observe(document.documentElement, { attributeFilter: ["data-theme"] });
    darkQuery.addEventListener("change", this.retheme);
  },

  destroyed() {
    this.observer.disconnect();
    darkQuery.removeEventListener("change", this.retheme);
  },
};

export { PodlovePlayer };
