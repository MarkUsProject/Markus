const path = require("path");
const webpack = require("webpack");
const MiniCssExtractPlugin = require("mini-css-extract-plugin");

const mode = process.env.NODE_ENV || "development";

module.exports = {
  mode: mode,
  devtool: "inline-source-map",
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
        test: /\.css$/i,
        use: [MiniCssExtractPlugin.loader, "css-loader"],
      },
      {
        test: /\.s[ac]ss$/i,
        use: [MiniCssExtractPlugin.loader, "css-loader", "sass-loader"],
      },
      {
        test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg|ico)$/i,
        use: "file-loader",
      },
    ],
  },
  optimization: {
    moduleIds: "hashed",
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[name].js.map",
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
    modules: [
      path.resolve(__dirname, "app/assets"),
      path.resolve(__dirname, "vendor/assets"),
      path.resolve(__dirname, "public/javascripts"),
      "node_modules",
    ],
  },
};
