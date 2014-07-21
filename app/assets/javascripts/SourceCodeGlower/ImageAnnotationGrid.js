/** Image Annotation Grid Class

    This is where most of the action happens:
    this class tracks/edits which Annotation Texts are connected to areas of the image.
    It requires a Image Event Handler, an Annotation Text Manager,
    and an Annotation Text Displayer be provided in the constructor.

    Rules:
    - A Source Code Line Manager, an Annotation Text Manager, and an
      Annotation Text Displayer must be provided in the constructor
*/

var HORIZONTAL_SCROLLBAR_COMPENSATION = 21;
var VERTICAL_SCROLLBAR_COMPENSATION   = 4;


function ImageAnnotationGrid(image_event_handler, annotation_text_manager, annotation_text_displayer) {
  this.image_event_handler       = image_event_handler;
  this.annotation_text_manager   = annotation_text_manager;
  this.annotation_text_displayer = annotation_text_displayer;

  this.process_grid();
  this.share_grid_with_event_handler();
  this.draw_holders();

  image_event_handler.init_listeners(document.getElementById('enable_annotations?').value);
  document.getElementById('image_preview').onmousemove = this.draw_holders.bind(this);
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
  var holder, annot_text_id, horiz_range, vert_range, holder_width,
      holder_height, holder_left, holder_top;

  // Edges of the image
  var image_preview   = document.getElementById('image_preview');
  var image_container = document.getElementById('image_container');
  var codeviewer      = document.getElementById('codeviewer');

  var top_edge    = image_preview.offsetTop + image_container.scrollTop;
  var left_edge   = image_preview.offsetLeft + image_container.scrollLeft;
  var right_edge  = image_preview.offsetLeft + image_container.scrollLeft + codeviewer.offsetWidth;
  var bottom_edge = image_preview.offsetTop + image_container.scrollTop + codeviewer.offsetHeight;

  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = annot_grid[i];

    annot_text_id = grid_element.id;
    horiz_range   = grid_element.x_range;
    vert_range    = grid_element.y_range;
    holder = document.getElementById('annotation_holder_' + annot_text_id);

    // Left offset of the holder
    holder_left = image_preview.offsetLeft + parseInt(horiz_range.start);
    // Top offset of the holder
    holder_top  = image_preview.offsetTop + parseInt(vert_range.start);

    holder_width  = parseInt(horiz_range.end) - parseInt(horiz_range.start);
    holder_height = parseInt(vert_range.end) - parseInt(vert_range.start);

    holder.style.left = Math.max(0, holder_left - left_edge) + image_preview.offsetLeft + 'px';
    holder.style.top  = Math.max(0, holder_top - top_edge) + image_preview.offsetTop + 'px';

    if (holder_left > right_edge || holder_top > bottom_edge || holder_left + holder_width < left_edge ||
        holder_top + holder_height < top_edge) {
      // Draw nothing, as holder is out of bounds of codeviewer
      holder.style.display = 'none';
    } else {
      // Holder within codeviewer, draw as much of it as fits.
      holder.style.display = 'block';
      holder.style.width  = Math.min(Math.min(holder_width, (holder_left + holder_width) - left_edge),
                                     right_edge - holder_left - VERTICAL_SCROLLBAR_COMPENSATION) + 'px';
      holder.style.height = Math.min(Math.min(holder_height, (holder_top + holder_height) - top_edge),
                                     bottom_edge - holder_top - HORIZONTAL_SCROLLBAR_COMPENSATION) + 'px';
    }
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
