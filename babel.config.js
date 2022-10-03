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
        ".",
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
          useBuiltIns: "entry",
          corejs: "3.22",
          modules: false,
          exclude: ["transform-typeof-symbol"],
        },
      ],
      require("@babel/preset-react"),
    ].filter(Boolean),
    plugins: [
      [
        require("@babel/plugin-transform-runtime").default,
        {
          helpers: false,
          regenerator: true,
        },
      ],
    ].filter(Boolean),
    sourceType: "unambiguous",
  };
};
