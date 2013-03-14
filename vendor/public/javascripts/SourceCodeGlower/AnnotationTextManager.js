/** Annotation Text Manager Class

This class is in charge of controlling the Annotation Texts

Rules:
- This class requires/assumes the Prototype javascript library
**/

var AnnotationTextManager = Class.create({
  initialize: function() {
    this.annotation_texts = $A();
  },
  annotationTextExists: function(annotation_text_id) {
    return this.annotation_texts[annotation_text_id] != null;
  },
  getAnnotationText: function(annotation_text_id) {
    if(!this.annotationTextExists(annotation_text_id)) {
      throw("Could not find an annotation with id: " + annotation_text_id);
    }
    return this.annotation_texts[annotation_text_id];
  },
  addAnnotationText: function(annotation_text) {
    if(this.annotationTextExists(annotation_text.getId())) {
      throw("An Annotation Text already exists with id: " + annotation_text.getId());
    }
    //Add the Annotation Text to our collection
    this.annotation_texts[annotation_text.getId()] = annotation_text;
  },
  removeAnnotationText: function(annotation_text_id) {
    if(!this.annotationTextExists(annotation_text_id)) {
      throw("No Annotation Text exists with id: " + annotation_text_id);
    }
    //Remove the Annotation Text from the collection
    this.annotation_texts[annotation_text_id] = null;
  },
  getAllAnnotationTexts: function() {
    var result = $A();
    this.annotation_texts.each(function(annotation_text) {
      result.push(annotation_text);
    });
    return result;
  }
});
