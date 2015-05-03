/** Image Annotation Grid Class
 *
 *  This is where most of the action happens:
 *  this class tracks/edits which Annotation Texts are connected to areas of the image.
 *  It requires a Image Event Handler, an Annotation Text Manager,
 *  and an Annotation Text Displayer be provided in the constructor.
 *
 *  Rules:
 *  - A Source Code Line Manager, an Annotation Text Manager, and an
 *    Annotation Text Displayer must be provided in the constructor
 */


function ImageAnnotationGrid(image_event_handler, annotation_text_manager, annotation_text_displayer) {
  this.image_event_handler       = image_event_handler;
  this.annotation_text_manager   = annotation_text_manager;
  this.annotation_text_displayer = annotation_text_displayer;

  this.process_grid();
  this.share_grid_with_event_handler();
  this.draw_holders();

  image_event_handler.init_listeners(document.getElementById('enable_annotations?').value);
  document.getElementById('codeviewer').onmousemove = this.draw_holders.bind(this);
}

ImageAnnotationGrid.prototype.getAnnotationTextManager = function() {
  return this.annotation_text_manager;
}

ImageAnnotationGrid.prototype.getImageEventHandler = function() {
  return this.image_event_handler;
}

ImageAnnotationGrid.prototype.getAnnotationTextDisplayer = function() {
  return this.annotation_text_displayer;
}

ImageAnnotationGrid.prototype.get_annotation_grid = function() {
  return this.annotation_grid;
}

ImageAnnotationGrid.prototype.process_grid = function() {
  this.annotation_grid = JSON.parse(document.getElementById('annotation_grid').value);
  var annot_grid = this.get_annotation_grid();
}

ImageAnnotationGrid.prototype.draw_holders = function() {
  var annot_grid = this.get_annotation_grid();

  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = annot_grid[i];

    var annot_text_id = grid_element.id;
    var horiz_range   = grid_element.x_range;
    var vert_range    = grid_element.y_range;

    var holder_left = parseInt(horiz_range.start, 10);
    var holder_top  = parseInt(vert_range.start, 10);

    var holder_width  = parseInt(horiz_range.end, 10) - parseInt(horiz_range.start, 10);
    var holder_height = parseInt(vert_range.end, 10) - parseInt(vert_range.start, 10);

    var holder = document.getElementById('annotation_holder_' + annot_text_id);

    holder.style.display = 'block';
    holder.style.left    = Math.max(0, holder_left) + 'px';
    holder.style.top     = Math.max(0, holder_top) + 'px';
    holder.style.width   = holder_width + 'px';
    holder.style.height  = holder_height + 'px';
  }
}

ImageAnnotationGrid.prototype.add_to_grid = function(extracted_coords) {
  // extracted_coords.x_range = { start: extracted_coords.x_range.start, end: extracted_coords.x_range.end };
  // extracted_coords.y_range = { start: extracted_coords.y_range.start, end: extracted_coords.y_range.end };

  this.annotation_grid.push(extracted_coords);
  this.share_grid_with_event_handler();

  var new_holder = document.createElement('div');
  new_holder.id = 'annotation_holder_' + extracted_coords.id;
  new_holder.addClass('annotation_holder');
  new_holder.onmousemove = this.getImageEventHandler().check_for_annotations.bind(this.getImageEventHandler());
  new_holder.onmousedown = this.getImageEventHandler().start_select_box.bind(this.getImageEventHandler());

  var image_preview = document.getElementById('image_preview');
  image_preview.parentNode.insertBefore(new_holder, image_preview);

  this.draw_holders();
}

ImageAnnotationGrid.prototype.remove_annotation = function(unused_param1, unused_param2, annotation_text_id) {
  if (this.getAnnotationTextManager().annotationTextExists(annotation_text_id)) {
    this.getAnnotationTextManager().removeAnnotationText(annotation_text_id);
  }

  var annot_grid = this.get_annotation_grid();
  for (var i = 0; i < annot_grid.length; i++) {
    if (annot_grid[i].id == annotation_text_id) {
      annot_grid.splice(i, 1);
      break;
    }
  }

  this.share_grid_with_event_handler();
}

ImageAnnotationGrid.prototype.registerAnnotationText = function(annotation_text) {
  // If the Annotation Text is already in the manager, we don't need to re-add it
  if (this.getAnnotationTextManager().annotationTextExists(annotation_text.getId())) {
    return;
  }

  this.getAnnotationTextManager().addAnnotationText(annotation_text);
}

// Call this any time the annotation_grid gets modified
ImageAnnotationGrid.prototype.share_grid_with_event_handler = function() {
  this.getImageEventHandler().set_annotation_grid(this.annotation_grid);
}

// Display the text associated with the annotation text id's inside annots_to_display.
// annots_to_display is an array of annotation text ids, and x and y are the
// coordinates relative to the page where the display box should pop up.
ImageAnnotationGrid.prototype.display_image_annotation = function(annots_to_display, x, y) {
  var collection = [];
  for (var i = 0; i < annots_to_display.length; i++) {
    collection.push(this.getAnnotationTextManager().getAnnotationText(annots_to_display[i]));
  }
  this.getAnnotationTextDisplayer().displayCollection(collection, x, y);
}
