const path = require("path");
const webpack = require("webpack");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

module.exports = {
  entry: {
    application_webpack: "./app/javascript/application_webpack.js",
    "pdf.worker": "./app/javascript/pdf.worker.js",
    result: "./app/javascript/result.js",
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
        use: [MiniCssExtractPlugin.loader, "css-loader", "sass-loader"],
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
