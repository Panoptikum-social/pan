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
      'blue-jeans': {
        light: '#5d9cec', 
        DEFAULT: '#4a89dc'
      },
      aqua: {
        light: '#4fc1e9', 
        DEFAULT: '#3bafda'
      },
      mint: {
        light: '#48cfad', 
        'mint-very-light': '#00c997',
        DEFAULT: '#37bc9b'
      },      
      grass: { 
        light: '#a0d468', 
        DEFAULT: '#8cc152'
      },
      sunflower: {
        light: '#ffce54', 
        DEFAULT: '#f6bb42'
      },
      bittersweet: {
        light: '#fc6e51', 
        DEFAULT: '#e9573f'
      },
      grapefruit: {
        light: '#ed5565', 
        DEFAULT: '#da4453'
      },
      lavender: {
        light: '#ac92ec', 
        DEFAULT: '#967adc'
      },
      'pink-rose': {
        light: '#ec87c0', 
        DEFAULT: '#d770ad'
      },

      // Bootflat colors: shades of gray
      white: '#ffffff',
      gray: {
        lightest: '#f5f7fa',
        lighter: '#e6e9ed',
        light: '#ccd1d9',
        DEFAULT: '#aab2bd',
        dark: '#656d78',
        darker: '#434a54'
      },
      black: '#000000',

      // Bootflat colors: functional colors
      'nav-background': '#434a54', // dark gray
      link: {
        dark: '#00644b', // mint-very-light
        DEFAULT: '#00c997' // mint-very-light
      },
      success: {
        light: '#b9df90',
        DEFAULT: '#8cc152', // grass
        dark: '#3c763d'
      },
      warning: {
        light: '#ffdd87',
        DEFAULT: '#f6bb42', // sunflower
        dark: '#8a6d3b'
      },
      danger: {
        light: '#f2838f',
        DEFAULT: '#da4453', // grapefruit
        dark: '#a94442'
      },
      info: {
        light: '#7cd1ef',
        DEFAULT: '#3bafda', // aqua
        dark: '#31708f'
      },
      podcast: {
        light: '#ffce54',  // sunflower-light
        DEFAULT: '#f6bb42' // sunflower
      },
      category: {
        light: '#fc6e51', // bittersweet-light
        DEFAULT: '#e9573f' // bittersweet
      },
      episode: {
        light: '#48cfad', // mint-light
        DEFAULT: '#37bc9b' // mint
      },
      recommendation: {
        light: '#ac92ec', // lavender-light
        DEFAULT: '#967adc' // lavender
      }
    },
  },
  variants: {
    extend: {
      backgroundColor: ['odd', 'even'],
    },
  },
}