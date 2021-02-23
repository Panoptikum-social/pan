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
    extend: {},
  },
  variants: {
    extend: {
      backgroundColor: ['odd', 'even'],
    },
  },
}