/** Annotation Text Displayer Class

This class is in charge of displaying collections of Annotation Texts.  It puts them
in a DIV with a class called "annotation_text_display" and is in charge of displaying
that DIV at given coordinates, and hiding that DIV.

Multiple texts are displayed at once, and each one is contained with a <p> tag.

Rules:
- This class requires/assumes the Prototype javascript library
- Assumes existence of AnnotationText class
**/

var TEXT_DISPLAY_X_OFFSET = 5;
var TEXT_DISPLAY_Y_OFFSET = 5;


var AnnotationTextDisplayer = Class.create({
  initialize: function(parent_node) {
    //Create the div that we will display in
		this.display_node = jQuery('<div>');
		this.display_node.addClass('annotation_text_display');
		this.display_node.mousemove(function(event) {
			hide_image_annotations();
		});

    jQuery(parent_node).append(this.display_node);
    this.hide();
  },
  //Assumes collection is subclass of Prototype Enumerable class
  //x and y is the location on the screen where this collection will display
  displayCollection: function(collection, x, y) {
    //Are we already showing some Annotations?  Hide them then
    this.hideShowing();
    //Return if the collection is empty
    if(collection.length == 0){ return;}
    //Now, compile all the annotations in this collection into a single
    //string to display.  Each text will be contained in a <p> tag
    var final_string = '';
    collection.each(function(annotation_text) {
      final_string += "<p>" + annotation_text.getContent() + "</p>";
    });
    
    //Update the Display node (a div, in this case) to be in the right
    //position, and to have the right contents
    final_string = final_string.replace(/\n/g, '<br/>');
    this.updateDisplayNode(final_string, x, y);
    
    //Show the Displayer
    this.show();
  },
  //Hide all showing annotations.
  hideShowing: function() {
    if(this.getShowing()) {
      this.hide();
    }
  },
  updateDisplayNode: function(text, x, y) {
    var display_node = jQuery(this.getDisplayNode());
    display_node.html(text);
    display_node.css('left', (x + TEXT_DISPLAY_X_OFFSET) + 'px');
    display_node.css('top', (y + TEXT_DISPLAY_Y_OFFSET) + 'px');
  },
  //Hide the displayer
  hide: function() {
    jQuery(this.display_node).hide();
  },
  //Show the displayer
  show: function() {
    jQuery(this.display_node).show();
  },
  //Returns whether or not the Displayer is showing
  getShowing: function() {
    return this.getDisplayNode().visible;
  },
  //Returns the DIV that we're displaying in
  getDisplayNode: function() {
    return jQuery(this.display_node);
  }
  
});
