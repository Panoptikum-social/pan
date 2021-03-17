const colors = require('tailwindcss/colors')

module.exports = {
  purge: {
    enabled: process.env.NODE_ENV === "production",
    content: [
      "../lib/**/templates/**/*.{leex,eex,ex}",
      "../lib/**/views/**/*.{ex,sface}",
      "../lib/**/live/**/*.{ex,sface}",
      "../lib/**/surface/**/*.{ex,sface}",
      "./js/**/*.js",  
    ],
    options: {
      whitelist: []
    }
  },
  plugins: [
    require('@tailwindcss/forms'),
  ],
  darkMode: false, // or 'media' or 'class'
  theme: {
    fontFamily: {
      sans: ['Ubuntu'],
      mono: ['Ubuntu\\ Mono'],
    },
    colors: {
      transparent: 'transparent',
      current: 'currentColor',
      // Bootflat colors: base
      'blue-jeans-light': '#5d9cec', 
      'blue-jeans': '#4a89dc',
      'aqua-light': '#4fc1e9', 
      aqua: '#3bafda',
      'mint-light': '#48cfad', 
      'mint-very-light': '#00c997',
      mint: '#37bc9b',
      'grass-light': '#a0d468', 
      grass: '#8cc152',
      'sunflower-light': '#ffce54', 
      sunflower: '#f6bb42',
      'bittersweet-light': '#fc6e51', 
      bittersweet: '#e9573f',
      'grapefruit-light': '#ed5565', 
      grapefruit: '#da4453',
      'lavender-light': '#ac92ec', 
      lavender: '#967adc',
      'pink-rose-light': '#ec87c0', 
      'pink-rose': '#d770ad',
      // Bootflat colors: shades of gray
      white: '#ffffff',
      'very-light-gray': '#f5f7fa',
      'light-gray': '#e6e9ed',
      'light-medium-gray': '#ccd1d9',
      'medium-gray': '#aab2bd',
      'medium-dark-gray': '#656d78',
      'dark-gray': '#434a54',
      black: '#000000',
      // Bootflat colors: functional colors
      'nav-background': '#434a54', // dark gray
      'link': '#00c997', // mint-very-light
      'success-light': '#b9df90',
      success: '#8cc152', // grass
      'success-dark': '#3c763d',
      'warning-light': '#ffdd87',
      warning: '#f6bb42', // sunflower
      'warning-dark': '#8a6d3b',
      'danger-light': '#f2838f',
      danger: '#da4453', // grapefruit
      'danger-dark': '#a94442',
      'info-light': '#7cd1ef',
      info: '#3bafda', // aqua
      'info-dark': '#31708f',
      'podcast-light': '#ffce54',  // sunflower-light
      podcast: '#f6bb42', // sunflower
      'category-light': '#fc6e51', // bittersweet-light
      category: '#e9573f', // bittersweet
      'episode-light': '#48cfad', // mint-light
      episode: '#37bc9b', // mint
      'recommendation-light': '#ac92ec', // lavender-light
      recommendation: '#967adc', // lavender
    },
  },
  variants: {
    extend: {
      backgroundColor: ['odd', 'even'],
    },
  },
}