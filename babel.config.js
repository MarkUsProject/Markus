module.exports = function (api) {
  var validEnv = ["development", "test", "production"];
  var currentEnv = api.env();
  var isDevelopmentEnv = api.env("development");
  var isProductionEnv = api.env("production");
  var isTestEnv = api.env("test");

  if (!validEnv.includes(currentEnv)) {
    throw new Error(
      "Please specify a valid `NODE_ENV` or " +
        '`BABEL_ENV` environment variables. Valid values are "development", ' +
        '"test", and "production". Instead, received: ' +
        JSON.stringify(currentEnv) +
        "."
    );
  }

  return {
    presets: [
      isTestEnv && [
        require("@babel/preset-env").default,
        {
          targets: {
            node: "current",
          },
        },
      ],
      (isProductionEnv || isDevelopmentEnv) && [
        require("@babel/preset-env").default,
        {
          forceAllTransforms: true,
          modules: false,
          exclude: ["transform-typeof-symbol"],
        },
      ],
      [
        require("@babel/preset-react").default,
        {
          runtime: "classic",
        },
      ],
    ].filter(Boolean),
    plugins: [
      (isProductionEnv || isDevelopmentEnv) && [
        require("babel-plugin-polyfill-corejs3").default,
        {
          method: "entry-global",
        },
      ],
      [
        require("babel-plugin-polyfill-regenerator").default,
        {
          method: "usage-pure",
        },
      ],
      [
        "prismjs",
        {
          languages: [
            "c",
            "cmake",
            "cpp",
            "css",
            "csv",
            "haskell",
            "html",
            "java",
            "javascript",
            "json",
            "jsx",
            "makefile",
            "markdown",
            "python",
            "r",
            "racket",
            "ruby",
            "scheme",
            "sh",
            "sql",
            "tex",
          ],
          plugins: ["line-numbers"],
          css: false,
        },
      ],
    ].filter(Boolean),
    sourceType: "unambiguous",
  };
};
