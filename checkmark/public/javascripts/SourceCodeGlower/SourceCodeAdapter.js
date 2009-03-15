/** Source Code Adapter Class

This adapts pre-existing source code, preparing it for the SourceCodeManager.  
This is a bit like an abstract class, and needs to be implemented for the particular method of adaptation.  Must return an indexable/Enumerable series of DOM nodes, where each is a source code line.

Rules:
- This class requires/assumes the Prototype javascript library
**/

var SourceCodeAdapter = Class.create({
  initialize: function(){},
  //Sets a particular source code line at a line number
  getSourceNodes: function() {
    throw("SourceCodeAdapter:getSourceNodes not implemented");
  },
  /**Given some node, trace up the tree until the node that is associated with Source Code Lines is found.  This is a workaround for dealing with window.getSelection().anchorNode/focusNode.**/
  getRootFromSelection: function(some_node) {
    throw("SourceCodeAdapter:getRootFromSelection not implemented");
  },
  applyMods: function() {
    throw("SourceCodeAdapter:applyMods not implemented");
  }
});
