// Syntax highlighting based on RStudio:
// https://github.com/rstudio/rstudio/blob/master/src/cpp/session/resources/r_highlight.html
dp.sh.Brushes.R = function()
{
  var keywords = 'if in break next repeat else for return switch while try ' +
    'stop warning require attach detach source setMethod setClass function ' +
    'tryCatch library setGeneric setGroupGeneric';

  var special = 'NA NA_integer_ NA_real_ NA_character_ NA_complex_';

  this.regexList = [
    { regex: dp.sh.RegexLib.SingleLinePerlComments, css: 'comment' },
    { regex: new RegExp('"(?!")(?:\\.|\\\\\\"|[^\\""\\n\\r])*"(?!")', 'gm'), css: 'string' },
    { regex: new RegExp("'(?!')*(?:\\.|(\\\\\\')|[^\\''\\n\\r])*'(?!')", 'gm'), css: 'string' },
    { regex: new RegExp("\\b\\d+\\.?\\w*", 'g'), css: 'number' },
    { regex: new RegExp(this.GetKeywords(keywords), 'gm'), css: 'keyword' },
    { regex: new RegExp(this.GetKeywords(special), 'gm'), css: 'special' }
  ];

  this.CssClass = 'dp-r';
}

dp.sh.Brushes.R.prototype  = new dp.sh.Highlighter();
dp.sh.Brushes.R.Aliases    = ['r'];
