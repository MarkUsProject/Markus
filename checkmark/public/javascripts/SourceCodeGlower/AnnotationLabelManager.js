/** Annotation Label Manager Class

This class is in charge of controlling the Annotation Labels

Rules:
- This class requires/assumes the Prototype javascript library
**/

var AnnotationLabelManager = Class.create({
  initialize: function() {
    this.annotation_labels = $A();
  },
  annotationLabelExists: function(annotation_label_id) {
    return this.annotation_labels[annotation_label_id] != null;
  },
  getAnnotationLabel: function(annotation_label_id) {
    if(!this.annotationLabelExists(annotation_label_id)) {
      throw("Could not find an annotation with id: " + annotation_label_id);
    }
    return this.annotation_labels[annotation_label_id];
  },
  addAnnotationLabel: function(annotation_label) {
    if(this.annotationLabelExists(annotation_label.getId())) {
      throw("An Annotation Label already exists with id: " + annotation_label.getId());
    }
    //Add the Annotation Label to our collection
    this.annotation_labels[annotation_label.getId()] = annotation_label;
  },
  removeAnnotationLabel: function(annotation_label_id) {
    if(!this.annotationLabelExists(annotation_label_id)) {
      throw("No Annotation Label exists with id: " + annotation_label_id);
    }
    //Remove the Annotation Label from the collection
    this.annotation_labels[annotation_label_id] = null;
  },
  getAllAnnotationLabels: function() {
    var result = $A();
    this.annotation_labels.each(function(annotation_label) {
      result.push(annotation_label);
    });
    return result;
  }
});
