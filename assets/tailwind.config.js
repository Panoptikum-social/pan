module.exports = {
  purge: {
    enabled: process.env.MIX_ENV === "prod",
    content: [
      "../lib/**/*.eex",
      "../lib/**/*.leex"
    ],
    options: {
      whitelist: []
    }
  },
  plugins: [require("kutty")]
}
