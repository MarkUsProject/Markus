/** Annotation Text Class

    This class holds the annotation texts in client memory.
*/

class AnnotationText {
  constructor(annotation_text_id, annotation_category_id, content) {
    this.annotation_text_id = annotation_text_id;
    this.annotation_category_id = annotation_category_id;
    this.content = content;
  }
}
