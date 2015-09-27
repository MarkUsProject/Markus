/** Source Code Line Array Class

    Implements Source Code Line Collection Class an array.
*/

function SourceCodeLineArray() {
  // Create the array that will hold the Source Code Lines
  this.collection = [];
}

SourceCodeLineArray.prototype = Object.create(SourceCodeLineCollection.prototype);

SourceCodeLineArray.prototype.constructor = SourceCodeLineArray;

// Sets a particular source code line at a line number
SourceCodeLineArray.prototype.set = function(line_num, source_code_line) {
  this.collection[line_num] = source_code_line;
}

SourceCodeLineArray.prototype.get = function(line_num) {
  return this.collection[line_num];
}

SourceCodeLineArray.prototype.getLineNumOfNode = function(line_node) {
  for (var i = 0; i < this.collection.length; i++) {
    var line = this.collection[i];
    if (line && line.getLineNode() === line_node) {
      return i - 1;
    }
  }
  return -1;
}
