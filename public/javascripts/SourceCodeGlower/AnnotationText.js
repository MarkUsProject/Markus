/** Annotation Text Class

This class holds the annotation texts in client memory.  

Rules:
- This class requires/assumes the Prototype javascript library
**/

var AnnotationText = Class.create({
  //Constructor:  Create the Annotation Text
  initialize: function(annotation_text_id, annotation_category_id, content) {
    this.annotation_text_id = annotation_text_id;
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
    return this.annotation_text_id
  },
  getCategoryId: function() {
    return this.annotation_category_id;
  }
});
