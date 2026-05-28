import {AnnotationText} from "./annotation_text";
import {AnnotationTextDisplayer} from "./annotation_text_displayer";
import {AnnotationTextManager} from "./annotation_text_manager";

/**
 * AbstractAnnotationManager class, used to manage the annotations for a submission.
 */
export class AbstractAnnotationManager {
  constructor() {
    this.annotation_text_displayer = new AnnotationTextDisplayer();
    this.annotation_text_manager = new AnnotationTextManager();

    this.annotations = {}; // Object mapping annotation id to annotation text and position
  }

  /**
   * Add a new annotation. Creates an annotation text with the given annotation_text_id
   * and content if one does not already exist.
   *
   * Returns a new object
   * @param annotation_text_id
   * @param content
   * @param range
   * @param annotation_id
   * @param is_remark
   */
  addAnnotation(annotation_text_id, content, range, annotation_id, is_remark) {
    let annotation_text = this.findOrCreateAnnotationText(annotation_text_id, content);
    let annotation = {
      annotation_id: annotation_id,
      annotation_text: annotation_text,
      range: range,
      is_remark: is_remark,
    };
    this.annotations[annotation_id] = annotation;
    return annotation;
  }

  /**
   * Remove the annotation with the given id. Return the removed annotation data.
   *
   * @param annotation_id
   */
  removeAnnotation(annotation_id) {
    let annotation = this.annotations[annotation_id];
    delete this.annotations[annotation_id];
    return annotation;
  }

  /**
   * Return the annotation text with the given id, or create one with the given content
   * if no such annotation text exists.
   *
   * @param annotation_text_id
   * @param content
   */
  findOrCreateAnnotationText(annotation_text_id, content) {
    if (this.annotation_text_manager.annotationTextExists(annotation_text_id)) {
      return this.annotation_text_manager.getAnnotationText(annotation_text_id);
    } else {
      let annotation_text = new AnnotationText(annotation_text_id, 0, content);
      this.annotation_text_manager.addAnnotationText(annotation_text);
      return annotation_text;
    }
  }

  /**
   * Returns the selection box coordinates (used when creating an annotation).
   * This is an abstract method that should be overridden by each AbstractAnnotationManager subclass.
   *
   * @param warn_no_selection  If true (default), display an alert to the user when there is no selection
   * @returns {object}
   */
  getSelection(warn_no_selection = true) {
    return {};
  }
}
