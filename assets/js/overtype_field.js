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

let OvertypeField = {
  mounted() {
    const textarea = this.el.querySelector("textarea");

    loadOverType().then(() => {
      const editorEl = document.createElement("div");
      this.el.replaceChild(editorEl, textarea);

      [this.editor] = new window.OverType(editorEl, {
        value: textarea.value,
        toolbar: true,
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
