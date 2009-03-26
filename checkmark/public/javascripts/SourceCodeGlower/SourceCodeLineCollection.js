/** Source Code Line Collection Class

This is an indexable collection of Source Code Lines.  This is a bit like an abstract
class, and needs to be implemented for the particular underlying collection type.

Rules:
- This class requires/assumes the Prototype javascript library
**/

var SourceCodeLineCollection = Class.create({
  initialize: function(){},
  //Sets a particular source code line at a line number
  set: function(line_num, source_code_line) {
    throw("SourceCodeCollection:set not implemented");
  },
  get: function(line_num) {
    throw("SourceCodeCollection:get not implemented");
  },
  each: function(each_func) {
    throw("SourceCodeCollection:each not implemented");
  },
  getLineNumOfNode: function(line_node) {
    throw("SourceCodeCollection:getLineNumOfNode not implemented");
  }
});
