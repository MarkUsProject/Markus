/* Scheme syntax contributed by ohyecloudy at gmail.com*/
dp.sh.Brushes.Scheme=function()
{
    var keywords=
        'and begin ' + 
        'call-with-current-continuation call-with-input-file call-with-output-file case cond ' + 
        'define define-syntax delay do dynamic-wind ' +
        'else for-each if ' +
        'lambda let let* let-syntax letrec letrec-syntax ' +
        'map or syntax-rules';

	this.regexList = [
		{ regex: new RegExp('( |^);.*$', 'gm'),				        css: 'comment' },
		{ regex: dp.sh.RegexLib.DoubleQuotedString,					css: 'string' },
		{ regex: new RegExp("'.[a-zA-Z0-9_\-]*", 'g'),              css: 'symbol' },
		{ regex: new RegExp(this.GetKeywords(keywords), 'gm'),		css: 'keyword' },
		{ regex: new RegExp('[()]', 'gm'),		                    css: 'parenthesis' }
		];

    this.CssClass = 'dp-scheme';
	this.Style =	'.dp-scheme .parenthesis { color: #843C24; }' +
					'.dp-scheme .symbol { color: #808080; font-weight: bold;}';
}

dp.sh.Brushes.Scheme.prototype	= new dp.sh.Highlighter();
dp.sh.Brushes.Scheme.Aliases	= ['scheme'];
