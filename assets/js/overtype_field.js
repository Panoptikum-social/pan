// OverType (MIT, self-hosted in priv/static/overtype) is only loaded on pages
// that use it. The hook replaces the server-rendered textarea by an editor
// whose own textarea carries the same name, so form submits work unchanged.
let overTypeLoading = null;

function loadOverType() {
  if (!overTypeLoading) {
    overTypeLoading = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      script.src = "/overtype/overtype.min.js";
      script.onload = resolve;
      script.onerror = reject;
      document.head.appendChild(script);
    });
  }
  return overTypeLoading;
}

// OverType's own themes (solar, cave) ignore ours. These colors are our CSS
// variables, so the editor follows Latte, Mocha and the theme toggle without
// a listener. OverType sets data-theme on its container, hence a name
// DaisyUI doesn't know.
const muted = (percent) =>
  `color-mix(in oklab, var(--color-base-content) ${percent}%, transparent)`;

const panTheme = {
  name: "pan",
  colors: {
    bgPrimary: "var(--color-base-100)",
    bgSecondary: "var(--color-base-100)",
    text: "var(--color-base-content)",
    textPrimary: "var(--color-base-content)",
    textSecondary: muted(70),
    h1: "var(--color-ctp-mauve)",
    h2: "var(--color-ctp-peach)",
    h3: "var(--color-ctp-green)",
    strong: "var(--color-ctp-peach)",
    em: "var(--color-ctp-pink)",
    del: "var(--color-ctp-red)",
    link: "var(--color-ctp-blue)",
    code: "var(--color-base-content)",
    codeBg: "var(--color-base-200)",
    blockquote: muted(70),
    hr: muted(50),
    syntaxMarker: muted(55),
    syntax: muted(50),
    cursor: "var(--color-primary)",
    selection: "color-mix(in oklab, var(--color-primary) 25%, transparent)",
    listMarker: "var(--color-ctp-peach)",
    rawLine: muted(70),
    border: "var(--color-base-300)",
    hoverBg: "var(--color-base-200)",
    primary: "var(--color-primary)",
    toolbarBg: "var(--color-base-200)",
    toolbarIcon: "var(--color-base-content)",
    toolbarHover: "var(--color-base-300)",
    toolbarActive: "var(--color-base-300)",
    placeholder: muted(50),
  },
};

let OvertypeField = {
  mounted() {
    const textarea = this.el.querySelector("textarea");

    loadOverType().then(() => {
      const editorEl = document.createElement("div");
      this.el.replaceChild(editorEl, textarea);

      [this.editor] = new window.OverType(editorEl, {
        value: textarea.value,
        toolbar: true,
        theme: panTheme,
        autoResize: true,
        minHeight: "200px",
        textareaProps: { name: textarea.name, id: textarea.id },
      });
    });
  },

  destroyed() {
    if (this.editor) this.editor.destroy();
  },
};

export { OvertypeField };
