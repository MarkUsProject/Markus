/**
 * Annotation Text Manager Class
 *
 * This class is in charge of controlling the Annotation Texts
 */

function AnnotationTextManager() {
  this.annotation_texts = [];
}

AnnotationTextManager.prototype.annotationTextExists = function(annotation_text_id) {
  return this.annotation_texts[annotation_text_id] != null;
}

AnnotationTextManager.prototype.getAnnotationText = function(annotation_text_id) {
  if (!this.annotationTextExists(annotation_text_id)) {
    throw("Could not find an annotation with id: " + annotation_text_id);
  }
  return this.annotation_texts[annotation_text_id];
}

AnnotationTextManager.prototype.addAnnotationText = function(annotation_text) {
  if (this.annotationTextExists(annotation_text.getId())) {
    throw("An Annotation Text already exists with id: " + annotation_text.getId());
  }
  // Add the Annotation Text to our collection
  this.annotation_texts[annotation_text.getId()] = annotation_text;
}

AnnotationTextManager.prototype.removeAnnotationText = function(annotation_text_id) {
  if (!this.annotationTextExists(annotation_text_id)) {
    throw("No Annotation Text exists with id: " + annotation_text_id);
  }
  // Remove the Annotation Text from the collection
  this.annotation_texts[annotation_text_id] = null;
}

AnnotationTextManager.prototype.getAllAnnotationTexts = function() {
  var result = [];
  for (var i = 0; i < this.annotation_texts.length; i++) {
    result.push(this.annotation_texts[i]);
  }
  return result;
}
