/**
 * SyntaxHighlighter
 * http://alexgorbatchev.com/
 *
 * SyntaxHighlighter is donationware. If you are using it, please donate.
 * http://alexgorbatchev.com/wiki/SyntaxHighlighter:Donate
 *
 * @version
 * 2.0.296 (March 01 2009)
 *
 * @copyright
 * Copyright (C) 2004-2009 Alex Gorbatchev.
 *
 * @license
 * This file is part of SyntaxHighlighter.
 *
 * SyntaxHighlighter is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SyntaxHighlighter is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SyntaxHighlighter.  If not, see <http://www.gnu.org/licenses/>.
 *
 *
 * Very simple Latex brush
 * http://www.jorgemarsal.com/blog/
 */

dp.sh.Brushes.Latex = function()
{
  var keywords =	'if fi then elif else for do done until while break continue case function return in eq ne gt lt ge le';
  //var commands =  'include usepackage begin end ref label includegraphics';

  this.regexList = [
    { regex: new RegExp('%.*','gm'),		css: 'comments' },		// one line comments
    { regex: dp.sh.RegexLib.DoubleQuotedString,			css: 'string' },		// double quoted strings
    { regex: new RegExp('\\\\\\w*','gm'),			css: 'keyword' },		// commands
    { regex: new RegExp(this.GetKeywords(keywords), 'gm'),			css: 'function' },		// keywords
  ];
}

dp.sh.Brushes.Latex.prototype = new dp.sh.Highlighter();
dp.sh.Brushes.Latex.Aliases   = ['latex', 'tex'];
