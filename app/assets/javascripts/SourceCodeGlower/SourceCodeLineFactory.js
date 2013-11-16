/** Source Code Line factory

This class just returns the type of Source Code lines that we're using

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of SourceCodeLine abstract class, and some implementation of that class
**/

var SourceCodeLineFactory = Class.create({
  initialize: function(){},
  build: function(node) {
    return new SyntaxHighlighter1p5Line(node);
  }
});
