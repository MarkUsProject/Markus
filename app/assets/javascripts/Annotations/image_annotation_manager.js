/**
 * AnnotationManager subclass for PDF files.
 *
 * @param {boolean} enable_annotations Whether annotations can be modified
 */
class ImageAnnotationManager extends AnnotationManager {
  constructor(enable_annotations) {
    super();
    this.enable_annotations = enable_annotations;

    this.sel_box = document.getElementById("sel_box");
    this.image_preview = document.getElementById("image_preview");

    this.render_holders();
    this.init_listeners();
  }

  /**
   * Add the given annotation to the image location specified by <range>.
   */
  addAnnotation(annotation_text_id, content, range, annotation_id, is_remark) {
    // Do nothing if annotation already exists.
    if (document.getElementById("annotation_holder_" + annotation_id) !== null) {
      return;
    }

    super.addAnnotation(annotation_text_id, content, range, annotation_id, is_remark);
    this.render_holders();
  }

  removeAnnotation(annotation_id) {
    super.removeAnnotation(annotation_id);

    let holder = document.getElementById("annotation_holder_" + annotation_id);
    if (holder !== null) {
      holder.parentElement.removeChild(holder);
    }
  }

  // Render the annotation overlays
  render_holders() {
    let horiz_range, vert_range, holder_width, holder_height, holder_left, holder_top;

    // Edges of the image
    let top_edge = 0;
    let left_edge = 0;
    let right_edge = Math.max(this.image_preview.width, this.image_preview.height);
    let bottom_edge = Math.max(this.image_preview.width, this.image_preview.height);

    for (let annotation_id in this.annotations) {
      let range = this.annotations[annotation_id].range;

      horiz_range = range.x_range;
      vert_range = range.y_range;
      if (horiz_range === undefined || vert_range === undefined) {
        continue;
      }

      // holder position and dimensions
      holder_left = this.image_preview.offsetLeft + parseInt(horiz_range.start, 10);
      holder_top = this.image_preview.offsetTop + parseInt(vert_range.start, 10);

      holder_width = parseInt(horiz_range.end, 10) - parseInt(horiz_range.start, 10);
      holder_height = parseInt(vert_range.end, 10) - parseInt(vert_range.start, 10);

      let holder = document.getElementById("annotation_holder_" + annotation_id);
      if (holder === null) {
        holder = document.createElement("div");
        holder.id = "annotation_holder_" + annotation_id;
        holder.addClass("annotation_holder");
        if (this.annotations[annotation_id].is_remark) {
          holder.addClass("remark");
        }
        holder.onmousemove = this.check_for_annotations.bind(this);
        if (this.enable_annotations) {
          holder.onmousedown = this.start_select_box.bind(this);
        } else {
          holder.style.cursor = "auto";
        }
        holder.onmouseleave = this.check_for_annotations.bind(this);

        this.image_preview.parentNode.insertBefore(holder, this.image_preview);
      }

      if (
        holder_left > right_edge ||
        holder_top > bottom_edge ||
        holder_left + holder_width < left_edge ||
        holder_top + holder_height < top_edge
      ) {
        // Draw nothing, as holder is out of bounds of codeviewer
        holder.style.display = "none";
      } else {
        // Holder within codeviewer, draw as much of it as fits.
        holder.style.left =
          Math.max(0, holder_left - left_edge) + this.image_preview.offsetLeft + "px";
        holder.style.top = Math.max(0, holder_top - top_edge) + this.image_preview.offsetTop + "px";

        holder.style.width =
          Math.min(holder_width, holder_left + holder_width - left_edge, right_edge - holder_left) +
          "px";
        holder.style.height =
          Math.min(holder_height, holder_top + holder_height - top_edge, bottom_edge - holder_top) +
          "px";

        holder.style.display = "block";
      }
    }
  }

  // Event handlers
  init_listeners() {
    this.image_preview.onmouseover = this.hide_image_annotations.bind(this);

    if (this.enable_annotations) {
      this.image_preview.onmousedown = this.start_select_box.bind(this);

      // Disable FireFox's default click and drag behaviour for images
      this.image_preview.ondragstart = function (e) {
        e.preventDefault();
      };

      document.getElementById("image_container").onmousemove = this.render_holders.bind(this);

      // Touch event handlers
      this.image_preview.addEventListener("touchstart", this.start_select_box_touch.bind(this));
    }
  }

  // Hide the currently displayed annotations
  hide_image_annotations() {
    this.annotation_text_displayer.hide();
  }

  check_for_annotations(e) {
    let xy_coords = get_absolute_cursor_pos(e);
    let annots_to_display = [];

    // Check if current mouse position is annotated
    for (let {annotation_text, range} of Object.values(this.annotations)) {
      if (
        range.x_range.start <= xy_coords[0] &&
        range.x_range.end >= xy_coords[0] &&
        range.y_range.start <= xy_coords[1] &&
        range.y_range.end >= xy_coords[1]
      ) {
        annots_to_display.push(annotation_text);
      }
    }

    if (annots_to_display.length > 0) {
      let image_container = document.getElementById("image_container");
      let codeviewer = document.getElementById("codeviewer");
      this.annotation_text_displayer.displayCollection(
        annots_to_display,
        xy_coords[0] + image_container.offsetLeft - codeviewer.scrollLeft,
        xy_coords[1] + image_container.offsetTop - codeviewer.scrollTop
      );
    } else {
      // No annotation found
      this.hide_image_annotations();
    }
  }

  /**
   * The following functions handle the selection box for creating a new annotation
   */

  // Start tracking the mouse to create an annotation.
  start_select_box(e) {
    this.hide_image_annotations();
    this.hide_selection_box();
    let xy_coords = get_absolute_cursor_pos(e);

    this.sel_box.orig_x = xy_coords[0];
    this.sel_box.orig_y = xy_coords[1];
    this.sel_box.style.display = "block";
    this.sel_box.style.left = xy_coords[0] + "px";
    this.sel_box.style.top = xy_coords[1] + "px";

    // Bind handlers for tracking mouse movement
    this.bound_mouse_move = this.mouse_move.bind(this);
    this.bound_stop_select_box = this.stop_select_box.bind(this);

    this.sel_box.addEventListener("mousemove", this.bound_mouse_move);
    this.sel_box.addEventListener("mouseup", this.bound_stop_select_box);
    this.image_preview.addEventListener("mousemove", this.bound_mouse_move);
    this.image_preview.addEventListener("mouseup", this.bound_stop_select_box);

    for (let annotation_id in this.annotations) {
      let holder = document.getElementById("annotation_holder_" + annotation_id);
      holder.removeEventListener("mousedown", this.bound_start_select_box);
      holder.addEventListener("mousemove", this.bound_mouse_move);
      holder.addEventListener("mouseup", this.bound_stop_select_box);
    }
  }

  // Stop tracking the mouse and open up modal to create an image annotation.
  stop_select_box() {
    this.sel_box.removeEventListener("mousemove", this.bound_mouse_move);
    this.sel_box.removeEventListener("mouseup", this.bound_stop_select_box);
    this.image_preview.removeEventListener("mousemove", this.bound_mouse_move);
    this.image_preview.removeEventListener("mouseup", this.bound_stop_select_box);

    for (let annotation_id in this.annotations) {
      let holder = document.getElementById("annotation_holder_" + annotation_id);
      holder.removeEventListener("mousemove", this.bound_mouse_move);
      holder.removeEventListener("mouseup", this.bound_stop_select_box);

      // Re-bind the start handler
      if (!this.bound_start_select_box) {
        this.bound_start_select_box = this.start_select_box.bind(this);
      }
      holder.addEventListener("mousedown", this.bound_start_select_box);
    }
  }

  hide_selection_box() {
    this.sel_box.style.display = "none";
    this.sel_box.style.width = "0px";
    this.sel_box.style.height = "0px";
  }

  // Draw red selection outline
  mouse_move(e) {
    let xy_coords = get_absolute_cursor_pos(e);

    this.sel_box.style.left = Math.min(xy_coords[0], this.sel_box.orig_x) + "px";
    this.sel_box.style.width = Math.abs(xy_coords[0] - this.sel_box.orig_x) + "px";
    this.sel_box.style.top = Math.min(xy_coords[1], this.sel_box.orig_y) + "px";
    this.sel_box.style.height = Math.abs(xy_coords[1] - this.sel_box.orig_y) + "px";
  }

  /**
   * Touch event handlers for creating annotations
   */

  // Start tracking the touch to create an annotation.
  start_select_box_touch(e) {
    // Prevent default to avoid scrolling while annotating
    e.preventDefault();

    this.hide_image_annotations();
    this.hide_selection_box();
    let touch = e.touches[0];
    let xy_coords = get_absolute_cursor_pos_touch(touch);

    this.sel_box.orig_x = xy_coords[0];
    this.sel_box.orig_y = xy_coords[1];
    this.sel_box.style.display = "block";
    this.sel_box.style.left = xy_coords[0] + "px";
    this.sel_box.style.top = xy_coords[1] + "px";

    // Bind handlers for tracking touch movement
    this.bound_touch_move = this.touch_move.bind(this);
    this.bound_stop_select_box_touch = this.stop_select_box_touch.bind(this);

    this.sel_box.addEventListener("touchmove", this.bound_touch_move);
    this.sel_box.addEventListener("touchend", this.bound_stop_select_box_touch);
    this.image_preview.addEventListener("touchmove", this.bound_touch_move);
    this.image_preview.addEventListener("touchend", this.bound_stop_select_box_touch);

    for (let annotation_id in this.annotations) {
      let holder = document.getElementById("annotation_holder_" + annotation_id);
      holder.removeEventListener("touchstart", this.bound_start_select_box_touch);
      holder.addEventListener("touchmove", this.bound_touch_move);
      holder.addEventListener("touchend", this.bound_stop_select_box_touch);
    }
  }

  // Stop tracking the touch and open up modal to create an image annotation.
  stop_select_box_touch() {
    this.sel_box.removeEventListener("touchmove", this.bound_touch_move);
    this.sel_box.removeEventListener("touchend", this.bound_stop_select_box_touch);
    this.image_preview.removeEventListener("touchmove", this.bound_touch_move);
    this.image_preview.removeEventListener("touchend", this.bound_stop_select_box_touch);

    for (let annotation_id in this.annotations) {
      let holder = document.getElementById("annotation_holder_" + annotation_id);
      holder.removeEventListener("touchmove", this.bound_touch_move);
      holder.removeEventListener("touchend", this.bound_stop_select_box_touch);

      // Re-bind the start handler
      if (!this.bound_start_select_box_touch) {
        this.bound_start_select_box_touch = this.start_select_box_touch.bind(this);
      }
      holder.addEventListener("touchstart", this.bound_start_select_box_touch);
    }
  }

  // Draw red selection outline for touch
  touch_move(e) {
    // Prevent default to avoid scrolling while annotating
    e.preventDefault();

    let touch = e.touches[0];
    let xy_coords = get_absolute_cursor_pos_touch(touch);

    this.sel_box.style.left = Math.min(xy_coords[0], this.sel_box.orig_x) + "px";
    this.sel_box.style.width = Math.abs(xy_coords[0] - this.sel_box.orig_x) + "px";
    this.sel_box.style.top = Math.min(xy_coords[1], this.sel_box.orig_y) + "px";
    this.sel_box.style.height = Math.abs(xy_coords[1] - this.sel_box.orig_y) + "px";
  }

  getSelection(warn_no_selection = true) {
    let box = this.get_selection_box_coordinates();
    if (!box) {
      if (warn_no_selection) {
        alert(I18n.t("results.annotation.select_an_area"));
      }
      return false;
    }
    return box;
  }

  get_selection_box_coordinates() {
    let img = this.image_preview;
    let zoomHeight = img.height;
    let zoomWidth = img.width;
    let zoomedRotatedWidth;
    let zoomedRotatedHeight;

    if (img.className === "rotate90" || img.className === "rotate270") {
      zoomedRotatedWidth = zoomHeight;
      zoomedRotatedHeight = zoomWidth;
    } else {
      zoomedRotatedWidth = zoomWidth;
      zoomedRotatedHeight = zoomHeight;
    }
    let imageHalfWidth = zoomedRotatedWidth / 2;
    let imageHalfHeight = zoomedRotatedHeight / 2;

    let box = this.sel_box;
    let unzoom = 1 / img.dataset.zoom;

    let leftCornerX = parseInt(box.style.left, 10);
    let leftCornerY = parseInt(box.style.top, 10);
    let annotationWidth = parseInt(box.style.width, 10);
    let annotationHeight = parseInt(box.style.height, 10);

    let topLeft = [leftCornerX - imageHalfWidth, leftCornerY - imageHalfHeight];
    let topRight = [topLeft[0] + annotationWidth, topLeft[1]];
    let bottomLeft = [topLeft[0], topLeft[1] + annotationHeight];
    let bottomRight = [topRight[0], bottomLeft[1]];

    let rotatedTR;
    let rotatedTL;
    let rotatedBL;
    let rotatedBR;
    let corners;

    if (img.className === "rotate90") {
      rotatedTR = [topRight[1], -topRight[0]];
      rotatedTL = [topLeft[1], -topLeft[0]];
      rotatedBR = [bottomRight[1], -bottomRight[0]];
      corners = [rotatedTL, rotatedTR, rotatedBR];
    } else if (img.className === "rotate180") {
      rotatedTR = [-topRight[0], -topRight[1]];
      rotatedBR = [-bottomRight[0], -bottomRight[1]];
      rotatedBL = [-bottomLeft[0], -bottomLeft[1]];
      corners = [rotatedTR, rotatedBR, rotatedBL];
    } else if (img.className === "rotate270") {
      rotatedBR = [-bottomRight[1], bottomRight[0]];
      rotatedBL = [-bottomLeft[1], bottomLeft[0]];
      rotatedTL = [-topLeft[1], topLeft[0]];
      corners = [rotatedBR, rotatedBL, rotatedTL];
    } else {
      corners = [bottomLeft, topLeft, topRight];
    }

    let x1 = (zoomWidth / 2 + corners[1][0]) * unzoom;
    let y1 = (zoomHeight / 2 + corners[1][1]) * unzoom;
    let x2 = (zoomWidth / 2 + corners[2][0]) * unzoom;
    let y2 = (zoomHeight / 2 + corners[0][1]) * unzoom;

    if (x2 - x1 < 1 || isNaN(x2 - x1)) {
      return false;
    } else {
      return {x1: x1, x2: x2, y1: y1, y2: y2};
    }
  }
}

// Get the coordinates of the mouse pointer relative to image container
// and return them in an array of the form [x, y].
// Taken from http://www.quirksmode.org/js/events_properties.html#positions
function get_absolute_cursor_pos(e) {
  let posx = 0;
  let posy = 0;

  if (!e) return [0, 0];

  if (e.pageX || e.pageY) {
    posx = e.pageX;
    posy = e.pageY;
  } else if (e.clientX || e.clientY) {
    posx = e.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
    posy = e.clientY + document.body.scrollTop + document.documentElement.scrollTop;
  }

  let image_container = document.getElementById("image_container");
  let codeviewer = document.getElementById("codeviewer");
  posx -= image_container.offsetLeft - codeviewer.scrollLeft;
  posy -= image_container.offsetTop - codeviewer.scrollTop;

  return [posx, posy];
}

// Get the coordinates of a touch event relative to image container
// and return them in an array of the form [x, y].
function get_absolute_cursor_pos_touch(touch) {
  let posx = 0;
  let posy = 0;

  if (!touch) return [0, 0];

  if (touch.pageX || touch.pageY) {
    posx = touch.pageX;
    posy = touch.pageY;
  } else if (touch.clientX || touch.clientY) {
    posx = touch.clientX + document.body.scrollLeft + document.documentElement.scrollLeft;
    posy = touch.clientY + document.body.scrollTop + document.documentElement.scrollTop;
  }

  let image_container = document.getElementById("image_container");
  let codeviewer = document.getElementById("codeviewer");
  posx -= image_container.offsetLeft - codeviewer.scrollLeft;
  posy -= image_container.offsetTop - codeviewer.scrollTop;

  return [posx, posy];
}
