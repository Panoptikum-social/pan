const colors = require('tailwindcss/colors')

module.exports = {
  purge: {
    enabled: process.env.MIX_ENV === "prod",
    content: [
      "../lib/**/*.eex",
      "../lib/**/*.leex",
      "../**/views/**/*.ex",
      "../**/live/**/*.ex",
      "./js/**/*.js",  
    ],
    options: {
      whitelist: []
    }
  },
  plugins: [
    require("kutty"),
    require('@tailwindcss/forms'),
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    fontFamily: {
      sans: ['Ubuntu'],
      mono: ['Ubuntu\\ Mono'],
    },
    extend: {
      colors: {
        amber: colors.amber,
        blueGray: colors.blueGray,
        coolGray: colors.coolGray,
        cyan: colors.cyan,
        emerald: colors.emerald,
        fuchsia: colors.fuchsia,
        lime: colors.lime,
        lightBlue: colors.lightBlue,
        orange: colors.orange,
        rose: colors.rose,
        teal: colors.teal,
        trueGray: colors.trueGray,
        violet: colors.violet,
        warmGray: colors.warmGray,
      },
    },
  },
  variants: {
    extend: {
      backgroundColor: ['odd', 'even'],
    },
  },
}