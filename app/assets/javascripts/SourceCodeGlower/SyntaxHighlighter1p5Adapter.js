/** Syntax Highlighter 1.5 Adapter Class

This class implements the SourceCodeAdapter abstract class.

This takes the DOM elements that the Syntax Highlighter library creates, and generates the DOM nodes that we're looking for.

This class also does any modifications / hackery necessary to the Syntax Highlighter.  In this case, it implements the font increase and decrease functions

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of SourceCodeAdapter abstract class
**/

var SyntaxHighlighter1p5Adapter = Class.create(SourceCodeAdapter, {
  //Syntax Highlighter generates an Ordered List DOM tree.  For this adapter,
  //we pass it the root of that tree...
  initialize: function(root_of_ol){
    this.root = $(root_of_ol);
    this.font_size = 1;
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
    return current_node;
  },
  getFontSize: function() {
    return this.font_size;
  },
  setFontSize: function(font_size) {
    this.font_size = font_size;
  },
  applyMods: function() {
    //We're going to extend Syntax Highlighters menu, and give it some new
    //commands
    if(dp == null) {
      throw("Could not modify Syntax Highlighter:  DP doesn't exist");
    }
    
    me = this;
     
    var original_commands = dp.sh.Toolbar.Commands;
    // Get rid of copyToClipboard
    delete original_commands['CopyToClipboard'];
    delete original_commands['PrintSource'];
    original_commands["BoostCode"] = {
    	  label: '+A',
	  func: function(highlighter) {
	    var code = $$('.dp-highlighter').first();
	    var font_size = me.getFontSize() + .25;
	    me.setFontSize(font_size);
            code.setStyle({fontSize: font_size + 'em'});
	  }
        };
    original_commands["ShrinkCode"] = {    
          label: '-A',
          func: function(highlighter) {
            var code = $$('.dp-highlighter').first();
            var font_size = me.getFontSize() - .25;
            me.setFontSize(font_size);
            code.setStyle({fontSize: font_size + 'em'});
          }
        };
    // A hack to put the About at the end
    var about = original_commands['About'];
    delete original_commands['About'];
    original_commands['About'] = about;
    
    //Attempt to replace tools menu with these new commands
    $$('.tools').first().update(dp.sh.Toolbar.Create('code').innerHTML)
    
    //Now we're going to move the tool bar to the new DIV *outside* of the SyntaxHighlighter
    //pane
    var ordered_list_of_code = $$('.dp-highlighter').first().immediateDescendants()[1];
    
    ordered_list_of_code.addClassName('code_scroller');

  }
});
