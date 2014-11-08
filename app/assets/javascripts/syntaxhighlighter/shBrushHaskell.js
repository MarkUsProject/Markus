/**
 * Haskell Brush for Code Syntax Highlighter Version 1.5.1
 * Version 0.1
 * Copyright (C) 2008 Cristiano Paris <cristiano.paris@gmail.com>
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, version 3 of the License.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
SyntaxHighlighter.brushes.Haskell = function()
{
        var _split = function(str)
                     {
                       return "\\s"+str.replace(/ /g,"\\s|\\s").replace(/>/g, '&gt;').replace(/</g, '&lt;')+"\\s";
                     }
 
        var keywords = 'case class data deriving do else if in infixl infixr instance let module of' + 
                       'primitive then type where import as hiding qualified newtype default';
                       
        var control = 'do if then else'                
        var syntax_operators = '=> -> <- :: \\'; 
        var prelude_funcs = '\\$! catch !! \\$ && \\+\\+ . =<< minBound maxBound succ pred toEnum fromEnum enumFrom enumFromThen enumFromTo enumFromThenTo == /= pi exp sqrt log \\*\\* \\(\\*\\*\\) logBase sin tan cos asin atan acos sinh tanh cosh asinh atanh acosh / recip fromRational quot rem div mod quotRem divMod toInteger \\(>>=\\) >>= \\(>>\\) >> return fail \\(\\+\\) \\+ \\(\\*\\) \\* \\(\\-\\) \\- negate abs signum fromInteger compare \\(<\\) < \\(>=\\) >= \\(>\\) > \\(<=\\) <= max min readsPrec readList floatRadix floatDigits floatRange decodeFloat encodeFloat exponent significand scaleFloat isNaN isInfinite isDenormalized isNegativeZero isIEEE atan2 properFraction truncate round ceiling floor showsPrec show showList \\(\\^\\) \\^ \\(\\^\\^\\) \\^\\^ all and any appendFile asTypeOf break concat concatMap const curry cycle drop dropWhile either elem error even filter flip foldl foldl1 foldr foldr1 fromIntegral fst gcd getChar getContents getLine head id init interact ioError iterate last lcm length lex lines lookup map mapM mapM_ maximum maybe minimum not notElem null odd or otherwise print product putChar putStr putStrLn read readFile readIO readLn readParen reads realToFrac repeat replicate reverse scanl scanl1 scanr scanr1 seq sequence sequence_ showChar showParen showString shows snd span splitAt subtract sum tail take takeWhile uncurry undefined unlines until unwords unzip unzip3 userError words writeFile zip zip3 zipWith zipWith3 \\(\\|\\|\\) \\|\\|'
        var common_operators = "\\$ \\. >>= >> <\\$> <\\*> \\+\\+ \\+ \\- \\*";
 
        this.regexList = [
                { regex: /--.*$/gm, css: 'comments' },                      			// one line comments
                { regex: /{-[\s\S]*?-}/gm, css: 'comments' },                      	        // multiline comments
                { regex: SyntaxHighlighter.regexLib.doubleQuotedString,  css: 'string' },   		// double quoted strings
                { regex: SyntaxHighlighter.regexLib.singleQuotedString,  css: 'string' },   		// single quoted strings
                { regex: new RegExp('^ *#.*', 'gm'), css: 'preprocessor' },			// preprocessor
                { regex: new RegExp(this.getKeywords(keywords), 'g'), css: 'keyword' },     	// keyword
                { regex: new RegExp(_split(syntax_operators), 'g'), css: 'syntax_operators' },  // syntax operators
                { regex: new RegExp(_split(common_operators), 'g'), css: 'common_operators' },  // common operators
                { regex: new RegExp(_split(control), 'g'), css: 'control' },  // control structures
                { regex: /`\w+`/g, css: 'common_operators' },  					// common operators
                { regex: /\b[0-9][0-9]*\b/g, css: 'value' },  					// constant values
                { regex: /\b[A-Z]\w*\b/g, css: 'type_constructors' },  				// type constructors
                { regex: new RegExp(this.getKeywords(prelude_funcs), 'g'), css: 'prelude' },  // common operators
                         ];
        // 
        // this.CssClass = 'dp-hs';
        // 
        this.style = '.haskell.syntax_operators { color: #993300; }' +
                     '.haskell.common_operators { color: #993300; }' +
                     '.haskell.type_constructors { font-style: italic; }';
};
 
SyntaxHighlighter.brushes.Haskell.prototype     = new SyntaxHighlighter.Highlighter();
SyntaxHighlighter.brushes.Haskell.aliases       = ['haskell','hs'];