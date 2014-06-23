/** Source Code Line factory

    This class just returns the type of Source Code lines that we're using

    Rules:
    - Assumes existence of SourceCodeLine abstract class, and some implementation of that class
*/

function SourceCodeLineFactory() {}

SourceCodeLineFactory.prototype.build = function(node) {
  return new SyntaxHighlighter1p5Line(node);
}
