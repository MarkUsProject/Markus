/** Source Code Line Manager Class

This class takes some Source Code Adapter to construct its indexed collection of source
code lines.  This manager will command the Source Code Lines.

Rules:
- This class requires/assumes the Prototype javascript library
- A Source Code Adapter must be passed in the constructor
- Assumes existence of SourceCode class
- Uses a Source Code Line Collection to hold source code lines
**/

var SourceCodeLineManager = Class.create({
  initialize: function(adapter, line_factory, empty_collection) {
    //Uses a SourceCodeLineCollection to hold source code lines
    this.collection = empty_collection;
    //Take the passed adapter, and start pulling DOM nodes and indexes (line numbers)
    
    //Since it's easy to confuse scope when passing functions around, I'll temporarily
    //alias this as 'me'.
    var me = this;
    adapter.getSourceNodes().each(function(node, index) {
      var line = line_factory.build(node);
      //Index + 1 - source code lines are not 0 indexed.
      me.collection.set(index + 1, line);
    });
  },
  //Given a DOM node, see if it's one of the DOM nodes representing the source code,
  //and if so, return it's line number.  If not, return -1.
  getLineNumber: function(line_node) {
    return this.collection.getLineNumOfNode(line_node) + 1;
  },
  //Return the Source Code Line at line_num
  getLine: function(line_num) {
    return this.collection.get(line_num);
  }
});
