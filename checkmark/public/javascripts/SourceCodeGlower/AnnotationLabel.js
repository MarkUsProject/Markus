/** Annotation Label Class

This class holds the annotation labels in client memory.  

Rules:
- This class requires/assumes the Prototype javascript library
**/

var AnnotationLabel = Class.create({
  //Constructor:  Create the Annotation Label
  initialize: function(annotation_id, annotation_category_id, content) {
    this.annotation_id = annotation_id;
    this.annotation_category_id = annotation_category_id;
    this.content = content;
  },
  //Getters and Setters
  setContent: function(content) {
    this.content = content;
  },
  getContent: function() {
    return this.content;
  },
  getId: function() {
    return this.annotation_id
  }
});
