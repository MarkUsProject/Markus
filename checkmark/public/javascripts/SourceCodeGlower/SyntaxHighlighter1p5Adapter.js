/** Syntax Highlighter 1.5 Adapter Class

This class implements the SourceCodeAdapter abstract class.

This takes the DOM elements that the Syntax Highlighter library creates, and generates
the DOM nodes that we're looking for.

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of SourceCodeAdapter abstract class
**/

var SyntaxHighlighter1p5Adapter = Class.create(SourceCodeAdapter, {
  //Syntax Highlighter generates an Ordered List DOM tree.  For this adapter,
  //we pass it the root of that tree...
  initialize: function(root_of_ol){
    this.root = $(root_of_ol);
  },
  //Returns an Enumerable collection of DOM nodes representing the source code lines,
  //in order.
  getSourceNodes: function() {
    return this.root.immediateDescendants();
  },
  /**Given some node, traverses upwards until it finds the LI element that represents a line of code in SyntaxHighlighter.  This is useful for figuring out what text is currently selected, using window.getSelection().anchorNode / focusNode**/
  getRootFromSelection: function(some_node) {
    if(some_node == null) {
      return null;
    }
    var current_node = some_node;
    while(current_node != null && current_node.tagName != 'LI') {
      current_node = current_node.parentNode;
    }
    if(current_node === some_node) {
      return null;
    }
    return current_node;
  }
});
