exports.config = {
  files: {
    javascripts: {
      joinTo: {
        'js/app.js': /^(js\/)|(node_modules\/)/,
        'js/vendor.js': /^(vendor\/)/,
        'js/qrcode.js': /^(vendor\/qrcode.min.js)/
      }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": /^(css\/)/,
        "css/app_alt.css": /^(css_alt\/)/
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    assets: /^(static\/)/
  },

  paths: {
    watched: ["static", "css", "css_alt", "js", "vendor"],
    public: "../priv/static"
  },

  plugins: {
    babel: {
      ignore: [/vendor/]
    },
    sass: {
      mode: "native"
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    whitelist: ["phoenix",
                "phoenix_html",
                "jquery",
                "boostrap-notify"],
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    },
  }
};