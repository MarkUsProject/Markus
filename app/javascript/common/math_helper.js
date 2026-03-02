import {default as katexRenderMathInElement} from "katex/contrib/auto-render";

/**
 * Wrapper around KaTeX's renderMathInElement function that sets a
 * different default value for the delimiters options.
 */
export function renderMathInElement(elem, options) {
  if (!options) {
    options = {};
  }
  if (!options.delimiters) {
    options = {
      ...options,
      delimiters: [
        {left: "$$", right: "$$", display: true},
        {left: "$", right: "$", display: false},
        {left: "\\(", right: "\\)", display: false},
        {left: "\\[", right: "\\]", display: true},
        {left: "\\begin{equation}", right: "\\end{equation}", display: true},
        {left: "\\begin{align}", right: "\\end{align}", display: true},
        {left: "\\begin{alignat}", right: "\\end{alignat}", display: true},
        {left: "\\begin{gather}", right: "\\end{gather}", display: true},
        {left: "\\begin{CD}", right: "\\end{CD}", display: true},
      ],
    };
  }

  katexRenderMathInElement(elem, options);
}
