const path = require("path");
const webpack = require("webpack");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");
const CopyWebpackPlugin = require("copy-webpack-plugin");

module.exports = {
  entry: {
    application_webpack: "./app/javascript/application_webpack.js",
    dark_theme: "./app/javascript/dark_theme.js",
    light_theme: "./app/javascript/light_theme.js",
    "pdf.worker": "pdfjs-dist/build/pdf.worker.mjs",
    application: "./app/assets/stylesheets/entrypoints/application.scss",
    notebook_common: "./app/assets/stylesheets/entrypoints/notebook_common.scss",
    notebook_dark: "./app/assets/stylesheets/entrypoints/notebook_dark.scss",
    notebook_light: "./app/assets/stylesheets/entrypoints/notebook_light.scss",
    rmd: "./app/assets/stylesheets/entrypoints/rmd.scss",
    rmd_dark: "./app/assets/stylesheets/entrypoints/rmd_dark.scss",
  },
  module: {
    rules: [
      {
        test: /\.(js|jsx)$/i,
        exclude: /node_modules/,
        use: ["babel-loader"],
      },
      {
        test: /\.(sass|scss|css)$/i,
        use: [
          MiniCssExtractPlugin.loader,
          // url: false — asset URLs in CSS (fonts, images) are resolved by Rails/Propshaft at
          // serve time, not by webpack. Without this, css-loader tries to bundle them and fails.
          {loader: "css-loader", options: {url: false}},
          {loader: "postcss-loader"},
          {
            loader: "sass-loader",
            options: {
              sassOptions: {
                // Mirror the --load-path flags previously used by the standalone sass watcher,
                // so @use paths in SCSS entrypoints resolve the same way.
                loadPaths: [
                  path.resolve(__dirname, "node_modules"),
                  path.resolve(__dirname, "app/assets/stylesheets"),
                  path.resolve(__dirname, "vendor/assets/stylesheets"),
                ],
              },
            },
          },
        ],
      },
      {
        test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg|ico)$/i,
        type: "asset/resource",
      },
    ],
  },
  output: {
    path: path.resolve(__dirname, "app/assets/builds"),
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1,
    }),
    new MiniCssExtractPlugin(),
    new CopyWebpackPlugin({
      patterns: [
        {from: "node_modules/katex/dist/fonts", to: "fonts"},
        {from: "node_modules/pdfjs-dist/web/images", to: "images"},
      ],
    }),
    new webpack.ProvidePlugin({
      $: "jquery",
      jQuery: "jquery",
      React: "react",
      "window.jQuery": "jquery",
    }),
  ],
  resolve: {
    extensions: [".js", ".json", ".jsx"],
    fallback: {util: false},
    modules: [
      path.resolve(__dirname, "app/assets"),
      path.resolve(__dirname, "vendor/assets"),
      path.resolve(__dirname, "public/javascripts"),
      "node_modules",
    ],
  },
};
