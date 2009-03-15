/** Source Code Line Annotations Class

This is where most of the action happens:  this class tracks/edits which Annotation Labels are connected to which Source Code Lines.  It requires a Source Code Line Manager, an Annotation Label Manager, and an Annotation Label Displayer be provided in the constructor.

This class manages a many to many relationship between Source Code Lines and
Annotation Labels, and sets the events to display/hide the Annotation Labels

Rules:
- This class requires/assumes the Prototype javascript library
- A Source Code Line Manager, an Annotation Label Manager, and an Annotation Label Displayer must be provided in the constructor
**/


var SourceCodeLineAnnotations = Class.create({
  initialize: function(line_manager, annotation_label_manager, annotation_label_displayer) {
    //Make sure we got what we wanted...
    this.line_manager = line_manager;
    this.annotation_label_manager = annotation_label_manager;
    this.annotation_label_displayer = annotation_label_displayer;
    this.relationships = $A();
  },
  getLineManager: function() {
    return this.line_manager;
  },
  getAnnotationLabelManager: function() {
    return this.annotation_label_manager;
  },
  getAnnotationLabelDisplayer: function() {
    return this.annotation_label_displayer;
  },
  //Annotate a single Source Code Line
  annotateLine: function(annotation_id, line_num, annotation_label_id) {
    if(!this.getAnnotationLabelManager().annotationLabelExists(annotation_label_id)) {
      throw("Attempting to annotate using an id that doesn't exist: " + annotation_label_id);
    }
    if(this.relationshipExists(annotation_id, line_num, annotation_label_id)) {
      throw("This Source Code Line has already been annotated with this Annotation Label");
    }
    
    //Mark the relationship between this line_num, and annotation_id
    this.addRelationship(annotation_id, line_num, annotation_label_id);
    
    //Glow the Source Code Line
    var line = this.getLineManager().getLine(line_num);
    line.glow(); 
    
    //Add events so that when we mouse over this Source Code Line, we display
    //the annotations
    
    //Again, using 'me' to ease scoping problems
    var me = this;
    line.observe(
      function(event) {
        me.displayLabelsForLine(line_num, Event.pointerX(event), Event.pointerY(event));
      },
      function(event) {
        me.hideLabel();
      });
  },
  //Annotate a Range of Source Code Lines
  annotateRange: function(annotation_id, range, annotation_label_id) {
    //Javascript scope is confusing...assign 'this' to me,
    //so that we can see 'me' in the loop
    var me = this;
    range.each(function(line_num) {
      me.annotateLine(annotation_id, line_num, annotation_label_id);
    });
  },
  removeAnnotationFromLine: function(annotation_id, line_num, annotation_label_id) {
    this.removeRelationship(annotation_id, line_num, annotation_label_id);
    var line = this.getLineManager().getLine(line_num);
    line.unGlow();
    
    //If there are no more annotations on this line, stop observing mouseovers
    //and mousedowns
    if(!this.hasAnnotation(line_num)) {
      line.stopObserving();
    }
  },
  
  removeAnnotationFromRange: function(annotation_id, range, annotation_label_id) {
    var me = this;
    range.each(function(line_num) {
      me.removeAnnotationFromLine(annotation_id, line_num, annotation_label_id);
    });
  },
  
  registerAnnotationLabel: function(annotation_label) {
    //If the Annotation Label is already in the manager, we don't need to re-add it
    if(this.getAnnotationLabelManager().annotationLabelExists(annotation_label.getId())) {
      return;
    }
    this.getAnnotationLabelManager().addAnnotationLabel(annotation_label);
  },
  
  addRelationship: function(annotation_id, line_num, annotation_label_id) {
    if(this.relationshipExists(annotation_id, line_num, annotation_label_id)) {
      return true;
    }
    this.getRelationships().push($H({'line_num':line_num, 'annotation_label_id':annotation_label_id, 'annotation_id': annotation_id}));
  },
  
  getRelationships: function() {
    return this.relationships;
  },
  
  setRelationships: function(relationships) {
    this.relationships = relationships;
  },
  
  relationshipExists: function(annotation_id, line_num, annotation_label_id) {
    var result = null;
    //Search through relationships, looking to see if we have one that matches this
    this.getRelationships().each(function(relationship) {
      if(relationship.get('line_num') == line_num && relationship.get('annotation_label_id') == annotation_label_id && relationship.get('annotation_id') == annotation_id) {
        result = relationship;
      }
    });
    return result;
  },
  
  removeRelationship: function(annotation_id, line_num, annotation_label_id) {
    var relationship = this.relationshipExists(annotation_id, line_num, annotation_label_id);
    if(relationship == null) {
      throw("Could not remove a non-existent relationship");
    }
    //Remove the found relationship from the relationships array
    this.setRelationships(this.getRelationships().without(relationship));    
  },
  
  getAnnotationLabelsForLineNum: function(line_num) {
    var result = $A();
    var me = this;
    this.getRelationships().each(function(relationship) {
      if(relationship.get('line_num') == line_num) {
        result.push(me.getAnnotationLabelManager().getAnnotationLabel(relationship.get('annotation_label_id')));
      }
    });
    return result;
  },
  //Does this source code line have any annotations at all?
  hasAnnotation: function(line_num) {
    var me = this;
    var result = false;
    this.getRelationships().each(function(relationship) {
      if(relationship.get('line_num') == line_num) {
        result = true;
        $break;
      }
    });
    return result;
  },
  
  hideLabel: function() {
    this.getAnnotationLabelDisplayer().hide();
  },
  
  
  displayLabelsForLine: function(line_num, x, y) {
    var labels = this.getAnnotationLabelsForLineNum(line_num);
    this.getAnnotationLabelDisplayer().displayCollection(labels, x, y);
  }
});

