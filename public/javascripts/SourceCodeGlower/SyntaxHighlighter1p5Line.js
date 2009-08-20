/** Syntax Highlighter 1.5 Source Code Line Class

This class implements the SourceCodeLine abstract class.

This class just removes the "alt" class from the LI element before a glow is applied

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of SourceCodeLine abstract class
**/

var SyntaxHighlighter1p5Line = Class.create(SourceCodeLine, {
  initialize: function($super, line_node) {
    this.has_alt = $(line_node).hasClassName('alt');
    $super(line_node);
  },
  beforeGlow: function() {
    if(this.has_alt) {
      this.getLineNode().removeClassName('alt');
    }
  },
  afterUnGlow: function() {
  //If we've removed all glow, put the Syntax Highlighter alt css class back
    if(this.getGlowDepth() == 0 && this.has_alt) {
      this.getLineNode().addClassName('alt');
    }  
  }
});
