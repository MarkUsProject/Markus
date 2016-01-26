/** Image Event Handler

    This class manages the different events tied to the image to ensure appropriate behavior.
*/

function ImageEventHandler() {
  this.annotation_grid = [];
}

ImageEventHandler.prototype.init_listeners = function(enable_annotations) {
  var image_preview = document.getElementById('image_preview');
  var sel_box       = document.getElementById('sel_box');

  image_preview.style.cursor = 'auto';
  image_preview.onmouseover  = hide_image_annotations;
  sel_box.style.cursor = 'auto';

  var annot_grid = this.get_annotation_grid();
  if (enable_annotations) {
    image_preview.style.cursor = 'crosshair';
    image_preview.onmousedown  = this.start_select_box.bind(this);
    sel_box.style.cursor = 'crosshair';

    // Disable FireFox's default click and drag behaviour for images
    image_preview.ondragstart = function(e) { e.preventDefault(); }
  }

  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = document.getElementById('annotation_holder_' + annot_grid[i].annot_id);
    grid_element.onmousemove = this.check_for_annotations.bind(this);

    if (enable_annotations) {
      grid_element.onmousedown  = this.start_select_box.bind(this);
    } else {
      grid_element.style.cursor = 'auto';
    }
  }
}

ImageEventHandler.prototype.set_annotation_grid = function(annot_grid) {
  this.annotation_grid = annot_grid;
}

ImageEventHandler.prototype.get_annotation_grid = function() {
  return this.annotation_grid;
}

// Get the coordinates of the mouse pointer relative to page
// and return them in an array of the form [x, y].
// Taken from http://www.quirksmode.org/js/events_properties.html#positions
ImageEventHandler.prototype.get_absolute_cursor_pos = function(e) {
  var posx = 0;
  var posy = 0;

  if (!e) var e = window.event;

  if (e.pageX || e.pageY) {
    posx = e.pageX;
    posy = e.pageY;
  } else if (e.clientX || e.clientY) {
    posx = e.clientX + document.body.scrollLeft
            + document.documentElement.scrollLeft;
    posy = e.clientY + document.body.scrollTop
            + document.documentElement.scrollTop;
  }

  return [posx, posy];
}

// Start tracking the mouse to create an annotation.
ImageEventHandler.prototype.start_select_box = function(e) {
  hide_image_annotations();
  var xy_coords  = this.get_absolute_cursor_pos(e);
  var annot_grid = this.get_annotation_grid();

  var box = document.getElementById('sel_box');
  box.orig_x = xy_coords[0];
  box.orig_y = xy_coords[1];
  box.style.display = 'block';
  box.style.left    = xy_coords[0] + 'px';
  box.style.top     = xy_coords[1] + 'px';
  box.onmousemove = this.mouse_move.bind(this);
  box.onmouseup   = this.stop_select_box.bind(this);

  var image_preview = document.getElementById('image_preview');
  image_preview.onmousemove = this.mouse_move.bind(this);
  image_preview.onmouseup   = this.stop_select_box.bind(this);
  image_preview.onmousedown = null;

  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = document.getElementById('annotation_holder_' + annot_grid[i].annot_id);
    grid_element.onmousemove = this.mouse_move.bind(this);
    grid_element.onmouseup   = this.stop_select_box.bind(this);
    grid_element.onmousedown = null;
  }
}

// Stop tracking the mouse and open up modal to create an image annotation.
ImageEventHandler.prototype.stop_select_box = function(e) {
  var annot_grid = this.get_annotation_grid();

  var image_preview = document.getElementById('image_preview');
  image_preview.onmousemove = this.check_for_annotations.bind(this);
  image_preview.onmouseup   = null;
  image_preview.onmousedown = this.remove_select_box.bind(this);
  image_preview.onmousemove = null;

  var box = document.getElementById('sel_box');
  box.onmousemove = null;
  box.onmouseup   = null;

  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = document.getElementById('annotation_holder_' + annot_grid[i].annot_id);
    grid_element.onmousemove = this.check_for_annotations.bind(this);
    grid_element.onmousedown = this.start_select_box.bind(this);
    grid_element.onmouseup   = null;
  }
}

ImageEventHandler.prototype.remove_select_box = function() {
  var box = document.getElementById('sel_box');
  box.style.display = 'none';
  box.style.width   = '0';
  box.style.height  = '0';
  document.getElementById('image_preview').onmousedown = this.start_select_box.bind(this);
}

// Draw red selection outline
ImageEventHandler.prototype.mouse_move = function(e) {
  var xy_coords = this.get_absolute_cursor_pos(e);
  var box = document.getElementById('sel_box');

  if (xy_coords[0] >= box.orig_x) {
    box.style.left  = box.orig_x + 'px';
    box.style.width = (xy_coords[0] - box.orig_x) + 'px';
    // 4th quadrant
    if (xy_coords[1] >= box.orig_y) {
      box.style.top    = (box.orig_y) + 'px';
      box.style.height = (xy_coords[1] - box.orig_y) + 'px';
    }
    // 1st quadrant
    else {
      box.style.top    = (xy_coords[1]) + 'px';
      box.style.height = (box.orig_y - xy_coords[1]) + 'px';
    }
  } else {
    box.style.left  = (xy_coords[0]) + 'px';
    box.style.width = (box.orig_x - xy_coords[0]) + 'px';
    // 3rd quadrant
    if (xy_coords[1] >= box.orig_y){
      box.style.top    = (box.orig_y) + 'px';
      box.style.height = (xy_coords[1] - box.orig_y) + 'px';
    }
    // 2nd quadrant
    else {
      box.style.top    = (xy_coords[1]) + 'px';
      box.style.height = (box.orig_y - xy_coords[1]) + 'px';
    }
  }
}

ImageEventHandler.prototype.check_for_annotations = function(e) {
  // Do not check for annotations until file completely loaded
  // Otherwise JavaScript throws a lot of unnoticable exceptions, as
  // annotation_manager gets loaded last.
  if (this.get_annotation_grid == null || annotation_manager == null) {
    return;
  }

  var abs_xy = this.get_absolute_cursor_pos(e);

  // X/Y coords relative to the image
  var image_preview   = document.getElementById('image_preview');
  var image_container = document.getElementById('image_container');
  var codeviewer = document.getElementById('codeviewer');
  var xy_coords = [abs_xy[0] - image_preview.offsetLeft + image_container.scrollLeft,
                   abs_xy[1] - image_preview.offsetTop + codeviewer.scrollTop];
  var annot_grid = this.get_annotation_grid();
  var annots_to_display = [];

  // Check if current mouse position is annotated
  for (var i = 0; i < annot_grid.length; i++) {
    var grid_element = annot_grid[i];
    if (grid_element.x_range.start <= xy_coords[0] && grid_element.x_range.end >= xy_coords[0]) {
      if (grid_element.y_range.start <= xy_coords[1] && grid_element.y_range.end >= xy_coords[1]) {
        // Annotation found
        annots_to_display.push(grid_element.id);
      }
    }
  }

  if (annots_to_display.length > 0) {
    annotation_manager.display_image_annotation(annots_to_display, abs_xy[0], abs_xy[1]);
  } else {
    // No annotation found
    hide_image_annotations();
  }
}
