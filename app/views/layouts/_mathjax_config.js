window.MathJax = {
  startup: {
    typeset: false,
  },
  tex: {
    // Allow inline single dollar sign notation
    inlineMath: [
      ["$", "$"],
      ["\\(", "\\)"],
    ],
    processEnvironments: true,
    processRefs: false,
  },
  options: {
    ignoreHtmlClass: "tex2jax_ignore",
    processHtmlClass: "tex2jax_process",
  },
  svg: {
    fontCache: "global",
  },
};
