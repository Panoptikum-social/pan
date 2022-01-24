import SimpleMDE from "../../../priv/static/simplemde/simplemde.min.js"

let MarkdownField = {
  mounted() {
    if (!this.el.dataset.disabled) {
      new SimpleMDE({
        element: document.getElementById("simplemde"),
        spellChecker: false
      });
    }
  }
};

export { MarkdownField };