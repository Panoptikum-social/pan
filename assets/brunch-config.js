exports.config = {
  files: {
    javascripts: {
//    joinTo: "js/app.js"
      joinTo: {
        'js/app.js': /^(js\/)|(node_modules\/)/,
        'js/vendor.js': /^(vendor\/)/,
        'js/qrcode.js': /^(vendor\/qrcode.min.js)/
//        "js/app.js": /^js/,
//        "js/vendor.js": /^(?!js)/

      }

      // To change the order of concatenation of files, explicitly mention here
      // https://github.com/brunch/brunch/tree/master/docs#concatenation
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: "css/app.css"
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    assets: /^(static)/
  },

  paths: {
    watched: ["static", "css", "js", "vendor"],
    public: "../priv/static"
  },

  plugins: {
    babel: {
      ignore: [/vendor/]
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    whitelist: ["phoenix", "phoenix_html", "jquery"],
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    },
  }
};