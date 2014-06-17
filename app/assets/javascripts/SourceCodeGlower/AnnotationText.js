/** Annotation Text Class

    This class holds the annotation texts in client memory.
*/

// Constructor: Create the Annotation Text
function AnnotationText(annotation_text_id, annotation_category_id, content) {
  this.annotation_text_id = annotation_text_id;
  this.annotation_category_id = annotation_category_id;
  this.content = content;
}

// Getters and Setters
AnnotationText.prototype.setContent = function(content) {
  this.content = content;
}

AnnotationText.prototype.getContent = function() {
  return this.content;
}

AnnotationText.prototype.getId = function() {
  return this.annotation_text_id;
}

AnnotationText.prototype.getCategoryId = function() {
  return this.annotation_category_id;
}
