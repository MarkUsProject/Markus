/** Source Code Line Collection Class

    This is an indexable collection of Source Code Lines.  This is a bit like an abstract
    class, and needs to be implemented for the particular underlying collection type.
*/

function SourceCodeLineCollection() {}

// Sets a particular source code line at a line number
SourceCodeLineCollection.prototype.set = function(line_num, source_code_line) {
  throw('SourceCodeCollection: set not implemented');
}

SourceCodeLineCollection.prototype.get = function(line_num) {
  throw('SourceCodeCollection: get not implemented');
}

SourceCodeLineCollection.prototype.getLineNumOfNode = function(line_node) {
  throw('SourceCodeCollection: getLineNumOfNode not implemented');
}
