const path = require('path')

const BASE = path.resolve(path.join('priv', 'static', 'dist'))
const EXCLUDED = [
  /elm-stuff/,
  /node_modules/,
]

module.exports = [
  {
    entry: {
      poller: [path.resolve('ui/src/poller.js')],
    },

    output: {
      path: BASE,
      filename: '[name].js',
      libraryTarget: 'window',
    },

    module: {
      rules: [
        {
          test: /\.elm$/,
          exclude: EXCLUDED,
          use: {
            loader: 'elm-webpack-loader',
            options: {
              warn: true,
            },
          },
        },
      ],
    },
  },
  {
    entry: {
      fib: [path.resolve('wasm/src/fib.js')],
    },

    output: {
      path: BASE,
      filename: '[name].js',
      libraryTarget: 'window',
    },
  }
]
