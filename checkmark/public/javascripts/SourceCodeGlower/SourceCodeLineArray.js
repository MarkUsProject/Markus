/** Source Code Line Array Class

Implements Source Code Line Collection Class using a Prototype Array

Rules:
- This class requires/assumes the Prototype javascript library
**/

var SourceCodeLineArray = Class.create(SourceCodeLineCollection, {
  initialize: function() {
    //Create the array that will hold the Source Code Lines
    this.collection = $A();
  },
  //Sets a particular source code line at a line number
  set: function(line_num, source_code_line) {
    this.collection[line_num] = source_code_line;
  },
  get: function(line_num) {
    return this.collection[line_num];
  },
  each: function(each_func) {
    this.collection.each(each_func);
  }
});
