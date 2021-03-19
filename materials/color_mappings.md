# Color Mappings

aqua -> lightBlue-400
bittersweet -> red-500
blue-jeans -> blue-500
danger -> rose-600
danger-dark -> rose-700
danger-light -> rose-400
dark-gray -> coolGray-600
grapefruit -> rose-600
grass -> lime-500
info -> lightBlue-400
info-dark -> cyan-700
info-light -> lightBlue-300
lavender -> violet-400
light-gray -> coolGray-200
gray-light -> coolGray-300
medium-dark-gray -> coolGray-500
medium-gray -> coolGray-400
mint -> teal-500
nav-background -> coolGray-600
pink-rose -> pink-400
success -> lime-500
success-dark -> green-700
success-light -> lime-200
sunflower -> amber-400
very-light-gray -> blueGray-50
warning -> amber-400
warning-dark -> yellow-700
warning-light -> amber-200

## Colors needed for Bootflat schema

colors: {
  amber: colors.amber,
  blue: colors.blue,
  blueGray: colors.blueGray,
  coolGray: colors.coolGray,
  cyan: colors.cyan,
  green: colors.green,
  lightBlue: colors.lightBlue,
  lime: colors.lime,
  pink: colors.lime,
  red: colors.red,
  rose: colors.rose,
  teal: colors.teal,
  violet: colors.violet,
  yellow: colors.yellow
},

## Importing Colors for Bootflat in addition to default colors

extend: {
  colors: {
    amber: colors.amber,
    blueGray: colors.blueGray,
    coolGray: colors.coolGray,
    cyan: colors.cyan,
    lightBlue: colors.lightBlue,
    lime: colors.lime,
    rose: colors.rose,
    teal: colors.teal,
    violet: colors.violet,
  }
},

## All colors available in Tailwind

colors: {
  blue: colors.blue,
  gray: colors.gray,
  green: colors.green,
  indigo: colors.indigo,
  pink: colors.pink,
  purple: colors.purple,
  red: colors.red,
  yellow: colors.yellow
}

## Importing colors not available in Tailwind by default

extend: {
  colors: {
    amber: colors.amber,
    blueGray: colors.blueGray,
    coolGray: colors.coolGray,
    orange: colors.orange,
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
    warmGray: colors.warmGray
  }
}
