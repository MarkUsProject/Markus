/**
 * shBrushMarkdown.js
 * Adapted from https://gist.github.com/1979689
 *
 * @version
 * 1.0.0 (March 06 2012)
 *
 * @copyright
 * copyright (C) 2012 hekt <http://www.hekt.org/>.
 *
 * @license
 * MIT license
 */
dp.sh.Brushes.Markdown = function()
{
  this.regexList = [
    {regex: dp.sh.RegexLib.SingleLinePerlComments,
      css: 'comments'},        // comments
    {regex: new RegExp('.+\\n([=-]{4,})', 'gm'),
      css: 'functions' },      // headers
    {regex: new RegExp('^#+\\s+.*', 'gm'),
      css: 'functions' },      // headers
    {regex: new RegExp('^(>|&gt;)\\s+.*', 'gm'),
      css: 'string' },         // blockquotes
    {regex: new RegExp('^([0-9]+.|[*+-])\\s', 'gm'),
      css: 'keyword' },        // lists
    {regex: new RegExp('\\n\\n((\\s{4,}|\\t).*\\n?)+', 'gm'),
      css: 'constants' },      // code block
    {regex: new RegExp('^([*-_])(\\1{2,}|(\\s\\1){2,}).*', 'gm'),
      css: 'functions' },      // horizontal rules
    {regex: new RegExp('\\!?\\[[^\\]]*\\]\\s?(\\([^\\)]*\\)|\\[[^\\]]*\\])',
        'gm'),
      css: 'keyword'},         // links and images
    {regex: new RegExp('^\\s{0,3}\\[[^\\]]*\\]:\\s.*', 'gm'),
      css: 'string'},          // references
    {regex: new RegExp('\\*([^*\\s]([^*]|\\\\\\*)*[^*\\s]|[^*\\s])\\*',
        'gm'),
      css: 'italic' },         // emphasis *
    {regex: new RegExp('\\_([^_\\s]([^_]|\\\\_)*[^_\\s]|[^_\\s])_', 'gm'),
      css: 'italic' },         // emphasis _
    {regex: new RegExp('\\*{2}([^\\s]([^*]|\\\\\\*\\*|[^*]\\*[^*])*[^\\s]|[^*\\s])\\*{2}',
        'gm'),
      css: 'bold' },           // emphasis **
    {regex: new RegExp('__([^\\s]([^_]|\\\\__|[^_]_[^_])*[^\\s]|[^_\\s])__',
        'gm'),
      css: 'bold' },           // emphasis __
    {regex: new RegExp('`(\\\\`|[^`])+`', 'gm'),
      css: 'constants' },      // code `
    {regex: new RegExp('(`{2,}).*\\1', 'gm'),
      css: 'constants' },      // code ``
    {regex: new RegExp('(<|&lt;).+[:@].+(>|&gt;)', 'gm'),
      css: 'keyword' }         // automatic links
  ];

  this.CssClass = 'dp-markdown';
}

dp.sh.Brushes.Markdown.prototype  = new dp.sh.Highlighter();
dp.sh.Brushes.Markdown.Aliases    = ['markdown', 'md', 'mdt', 'rmarkdown', 'rmd'];
