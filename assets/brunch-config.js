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
    whitelist: ["phoenix",
                "phoenix_html",
                "jquery",
                "boostrap-notify",
                "@podlove/podlove-web-player"],
    globals: {
      $: 'jquery',
      jQuery: 'jquery'
    },
  }
};
