/** Source Code Line Annotations Class

    This is where most of the action happens:  this class tracks/edits which Annotation Texts are
    connected to which Source Code Lines.  It requires a Source Code Line Manager, an Annotation Text Manager,
    and an Annotation Text Displayer be provided in the constructor.

    This class manages a many to many relationship between Source Code Lines and
    Annotation Texts, and sets the events to display/hide the Annotation Texts

    Rules:
    - A Source Code Line Manager, an Annotation Text Manager, and an Annotation Text Displayer must be
      provided in the constructor
*/

function SourceCodeLineAnnotations(line_manager, annotation_text_manager, annotation_text_displayer) {
  // Make sure we got what we wanted...
  this.annotation_text_displayer = annotation_text_displayer;
  this.annotation_text_manager   = annotation_text_manager;
  this.line_manager  = line_manager;
  this.relationships = [];
}

SourceCodeLineAnnotations.prototype.getLineManager = function() {
  return this.line_manager;
}

SourceCodeLineAnnotations.prototype.getAnnotationTextManager = function() {
  return this.annotation_text_manager;
}

SourceCodeLineAnnotations.prototype.getAnnotationTextDisplayer = function() {
  return this.annotation_text_displayer;
}
// Annotate a single Source Code Line
SourceCodeLineAnnotations.prototype.annotateLine = function(
    annotation_id, line_num, column_start, column_end, annotation_text_id) {
  if (!this.getAnnotationTextManager().annotationTextExists(annotation_text_id)) {
    throw("Attempting to annotate using an id that doesn't exist: " + annotation_text_id);
  }
  if (this.relationshipExists(annotation_id, line_num, annotation_text_id)) {
    throw('This Source Code Line has already been annotated with this Annotation Text');
  }

  // Mark the relationship between this line_num, and annotation_id
  this.addRelationship(annotation_id, line_num, annotation_text_id);

  // Glow the Source Code Line
  var line = this.getLineManager().getLine(line_num);
  var this_ref = this;
  line.glow(annotation_id, column_start, column_end,
    function(event) {
      this_ref.displayTextsForLine(line_num, event, event.pageX, event.pageY);
    },
    function(event) {
      this_ref.hideText();
    }
  );
}

// Annotate a Range of Source Code Lines
SourceCodeLineAnnotations.prototype.annotateRange = function(annotation_id, range, annotation_text_id) {
  var line_start = parseInt(range.start, 10);
  var line_end = parseInt(range.end, 10);
  var column_start = parseInt(range.column_start, 10);
  var column_end = parseInt(range.column_end, 10);

  // If the highlight continues to the next line sent -1 to indicate the rest of the line should glow
  for (var line_num = line_start; line_num <= line_end; line_num++) {
    this.annotateLine(annotation_id,
      line_num,
      line_num == line_start ? column_start : 0,
      line_num == line_end ? column_end : -1,
      annotation_text_id);

  }
}

SourceCodeLineAnnotations.prototype.removeAnnotationFromLine = function(annotation_id, line_num, annotation_text_id) {
  this.removeRelationship(annotation_id, line_num, annotation_text_id);
  var line = this.getLineManager().getLine(line_num);
  line.unGlow(annotation_id);

  // If there are no more annotations on this line, stop observing mouseovers
  // and mousedowns
  if (!this.hasAnnotation(line_num)) {
    line.stopObserving();
  }
}

SourceCodeLineAnnotations.prototype.remove_annotation = function(annotation_id, range, annotation_text_id) {
  for (var line_num = parseInt(range.start, 10); line_num <= parseInt(range.end, 10); line_num++) {
    this.removeAnnotationFromLine(annotation_id, line_num, annotation_text_id);
  }
}

SourceCodeLineAnnotations.prototype.registerAnnotationText = function(annotation_text) {
  // If the Annotation Text is already in the manager, we don't need to re-add it
  if (this.getAnnotationTextManager().annotationTextExists(annotation_text.getId())) {
    return;
  }
  this.getAnnotationTextManager().addAnnotationText(annotation_text);
}

SourceCodeLineAnnotations.prototype.addRelationship = function(annotation_id, line_num, annotation_text_id) {
  if (this.relationshipExists(annotation_id, line_num, annotation_text_id)) {
    return true;
  }
  this.getRelationships().push({ 'line_num': line_num,
                                 'annotation_text_id': annotation_text_id,
                                 'annotation_id': annotation_id });
}

SourceCodeLineAnnotations.prototype.getRelationships = function() {
  return this.relationships;
}

SourceCodeLineAnnotations.prototype.setRelationships = function(relationships) {
  this.relationships = relationships;
}

SourceCodeLineAnnotations.prototype.relationshipExists = function(annotation_id, line_num, annotation_text_id) {
  // Search through relationships, looking to see if we have one that matches this
  var relationships = this.getRelationships();
  for (var i = 0; i < relationships.length; i++) {
    var relationship = relationships[i];
    if (relationship['line_num'] == line_num &&
        relationship['annotation_text_id'] == annotation_text_id &&
        relationship['annotation_id'] == annotation_id) {
      return relationship;
    }
  }
  return null;
}

SourceCodeLineAnnotations.prototype.removeRelationship = function(annotation_id, line_num, annotation_text_id) {
  var relationship = this.relationshipExists(annotation_id, line_num, annotation_text_id);

  // Just return if no relationship existed
  if (relationship == null) { return;   }

  // Remove the found relationship from the relationships array
  this.setRelationships(this.getRelationships().without(relationship));
}

SourceCodeLineAnnotations.prototype.getAnnotationTextsForLineNum = function(line_num, annotation_ids) {
  var result = [];

  var relationships = this.getRelationships();
  for (var i = 0; i < relationships.length; i++) {
    var relationship = relationships[i];
    if (relationship['line_num'] == line_num && annotation_ids.indexOf(
        relationship['annotation_id'].toString()) >= 0) {
      result.push(this.getAnnotationTextManager().getAnnotationText(relationship['annotation_text_id']));
    }
  }

  return result;
}

// Does this source code line have any annotations at all?
SourceCodeLineAnnotations.prototype.hasAnnotation = function(line_num) {
  var relationships = this.getRelationships();
  for (var i = 0; i < relationships.length; i++) {
    var relationship = relationships[i];
    if (relationship['line_num'] == line_num) {
      return true;
    }
  }

  return false;
}

SourceCodeLineAnnotations.prototype.hideText = function() {
  this.getAnnotationTextDisplayer().hide();
}

SourceCodeLineAnnotations.prototype.displayTextsForLine = function(line_num, event, x, y) {
  var annotationIDs = new Array();
  for (var i = 0; i < event.srcElement.attributes.length; i++) {
    var attribute = event.srcElement.attributes[i];
    if (attribute.name.indexOf("data-annotationid") >= 0){
      annotationIDs.push(attribute.value)
    }
  }
  var texts = this.getAnnotationTextsForLineNum(line_num, annotationIDs);
  this.getAnnotationTextDisplayer().displayCollection(texts, x, y);
}
