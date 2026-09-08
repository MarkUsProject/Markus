// Babel reads BABEL_ENV/NODE_ENV from the build process, not from webpack's
// mode. Without this, @babel/preset-react compiles JSX in development mode
// (jsxDEV calls), which React's production build does not provide.
process.env.BABEL_ENV = process.env.BABEL_ENV || "production";
process.env.NODE_ENV = process.env.NODE_ENV || "production";

const {merge} = require("webpack-merge");
const common = require("./webpack.common.js");

module.exports = merge(common, {
  mode: "production",
  devtool: "source-map",
});
