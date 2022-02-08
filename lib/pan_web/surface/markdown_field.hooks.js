let MarkdownField = {
  mounted() {
    if (!this.el.dataset.disabled) {
      const scripttag = document.createElement("script");
      scripttag.async = true;
      scripttag.src = "/simplemde/simplemde.min.js";
      scripttag.id = "simplemde_js";
      this.el.appendChild(scripttag);

      document
        .querySelector("#simplemde_js")
        .addEventListener("load", function () {
          new SimpleMDE({
            element: document.getElementById("simplemde"),
            spellChecker: false,
          });
        });
    }
  },
};

export { MarkdownField };
