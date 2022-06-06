/**
 * Annotation Text Manager Class
 *
 * This class is in charge of controlling the Annotation Texts
 */

class AnnotationTextManager {
  constructor() {
    this.annotation_texts = {};
  }

  annotationTextExists(annotation_text_id) {
    return this.annotation_texts.hasOwnProperty(annotation_text_id);
  }

  getAnnotationText(annotation_text_id) {
    return this.annotation_texts[annotation_text_id];
  }

  // Add an annotation text, overwriting any existing annotation texts with the same id
  addAnnotationText(annotation_text) {
    this.annotation_texts[annotation_text.annotation_text_id] = annotation_text;
  }

  // Remove the annotation text with the given id
  removeAnnotationText(annotation_text_id) {
    delete this.annotation_texts[annotation_text_id];
  }
}
