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
    annotationId, lineNum, columnStart, columnEnd, annotationTextId) {
  if (!this.getAnnotationTextManager().annotationTextExists(annotationTextId)) {
    throw("Attempting to annotate using an id that doesn't exist: " +
    annotationTextId);
  }
  if (this.relationshipExists(annotationId, lineNum, annotationTextId)) {
    throw("This Source Code Line has already been annotated with this " +
    "Annotation Text");
  }

  // Mark the relationship between this lineNum, and annotationId
  this.addRelationship(annotationId, lineNum, annotationTextId);

  // Glow the Source Code Line
  var line = this.getLineManager().getLine(lineNum);
  var thisReference = this;
  line.glow(annotationId.toString(), columnStart, columnEnd,
    function(event) {
      thisReference.displayTextsForLine(
        lineNum, event, event.pageX, event.pageY);
    },
    function(event) {
      thisReference.hideText();
    }
  );
}

// Annotate a Range of Source Code Lines
SourceCodeLineAnnotations.prototype.annotateRange = function(
  annotationId, range, annotationTextId) {
  var lineStart = parseInt(range.start, 10);
  var lineEnd = parseInt(range.end, 10);
  var columnStart = parseInt(range.column_start, 10);
  var columnEnd = parseInt(range.column_end, 10);

  // If the highlight continues to the next line sent -1 to
  // indicate the rest of the line should glow
  for (var lineNum = lineStart; lineNum <= lineEnd; lineNum++) {
    this.annotateLine(annotationId,
      lineNum,
      lineNum == lineStart ? columnStart : 0,
      lineNum == lineEnd ? columnEnd : -1,
      annotationTextId);
  }
}

SourceCodeLineAnnotations.prototype.removeAnnotationFromLine = function(
  annotationId, lineNum, annotationTextId) {
  this.removeRelationship(annotationId, lineNum, annotationTextId);
  var line = this.getLineManager().getLine(lineNum);
  line.unGlow(annotationId.toString());

  // If there are no more annotations on this line, stop observing mouseovers
  // and mousedowns
  if (!this.hasAnnotation(lineNum)) {
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

  // Clone relationships array and remove the found relationship
  var index = this.getRelationships().indexOf(relationship);
  var clonedRelationships = this.getRelationships().slice().splice(index,relationship);

  this.setRelationships(clonedRelationships);
}

SourceCodeLineAnnotations.prototype.getAnnotationTextsForLineNum = function(
  lineNum, annotationIds) {
  var result = [];

  var relationships = this.getRelationships();
  for (var i = 0; i < relationships.length; i++) {
    var relationship = relationships[i];
    if (relationship['line_num'] == lineNum && annotationIds.indexOf(
        relationship['annotation_id'].toString()) >= 0) {
      result.push(this.getAnnotationTextManager().getAnnotationText(
        relationship['annotation_text_id']));
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

SourceCodeLineAnnotations.prototype.displayTextsForLine = function(
  lineNum, event, x, y) {
  var annotationIDs = new Array();
  var source = (event.currentTarget) ? event.currentTarget : event.srcElement;
  for (var i = 0; i < source.attributes.length; i++) {
    var attribute = source.attributes[i];
    if (attribute.name.indexOf("data-annotationid") >= 0){
      annotationIDs.push(attribute.value)
    }
  }
  var texts = this.getAnnotationTextsForLineNum(lineNum, annotationIDs);
  this.getAnnotationTextDisplayer().displayCollection(texts, x, y);
}
