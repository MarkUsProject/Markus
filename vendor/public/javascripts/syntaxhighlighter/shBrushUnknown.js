/* Custom SyntaxHighlighter 'Brush' to let SyntaxHighlighter run on files that
it doesn't necessarily recognize.  Nothing is highlighted, but the text is still
compiled into an ordered list, etc. */

dp.sh.Brushes.Unknown = function()
{
  var keywords = ''
  var builtins = ''

  this.regexList = [];
  this.CssClass = 'dp-unknown';
  this.Style =	'';
}

dp.sh.Brushes.Unknown.prototype = new dp.sh.Highlighter();
dp.sh.Brushes.Unknown.Aliases = ['unknown'];
