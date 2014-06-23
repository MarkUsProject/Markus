/** Source Code Line Manager Class

    This class takes some Source Code Adapter to construct its indexed collection of source
    code lines.  This manager will command the Source Code Lines.

    Rules:
    - A Source Code Adapter must be passed in the constructor
    - Assumes existence of SourceCode class
    - Uses a Source Code Line Collection to hold source code lines
*/

function SourceCodeLineManager(adapter, line_factory, empty_collection) {
  // Uses a SourceCodeLineCollection to hold source code lines
  this.collection = empty_collection;

  // Take the passed adapter, and start pulling DOM nodes and indexes (line numbers)
  var source_nodes = adapter.getSourceNodes();

  for (var i = 0; i < source_nodes.length; i++) {
    // i + 1: source code lines are not 0 indexed
    this.collection.set(i + 1, line_factory.build(source_nodes[i]));
  }
}

// Given a DOM node, see if it's one of the DOM nodes representing the source code,
// and if so, return it's line number. If not, return -1.
SourceCodeLineManager.prototype.getLineNumber = function(line_node) {
  return this.collection.getLineNumOfNode(line_node) + 1;
}

// Return the Source Code Line at line_num
SourceCodeLineManager.prototype.getLine = function(line_num) {
  return this.collection.get(line_num);
}
