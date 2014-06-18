/** Syntax Highlighter 1.5 Source Code Line Class

    This class implements the SourceCodeLine abstract class.

    This class just removes the "alt" class from the LI element before a glow is applied

    Rules:
    - Assumes existence of SourceCodeLine abstract class
*/

function SyntaxHighlighter1p5Line(line_node) {
  SourceCodeLine.call(this, line_node);
}

SyntaxHighlighter1p5Line.prototype = Object.create(SourceCodeLine.prototype);

SyntaxHighlighter1p5Line.prototype.constructor = SyntaxHighlighter1p5Line;
