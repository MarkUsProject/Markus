/** Image Event Handler

This class manages the different events tied to the image to ensure appropriate behavior.

Rules:
- This class requires/assumes the Prototype javascript library
**/

var ImageEventHandler = Class.create({
    initialize: function(){
        this.annotation_grid = $A();
    },
    init_listeners: function(enable_annotations){
      $("image_preview").style.cursor = 'auto';
      $("sel_box").style.cursor = 'auto';
      $("image_preview").onmouseover = hide_image_annotations;
      var annot_grid = this.get_annotation_grid();
      if (enable_annotations == 'true') {
        $("image_preview").onmousedown = this.start_select_box.bind(this);
        $("image_preview").style.cursor = 'crosshair';
        $("sel_box").style.cursor = 'crosshair';
      }
      var me = this;
      annot_grid.each(function(grid_element) {
        $('annotation_holder_' + grid_element.id).style.cursor = 'auto';
        $('annotation_holder_' + grid_element.id).onmousemove = me.check_for_annotations.bind(me);
        if (enable_annotations == 'true') {
          $('annotation_holder_' + grid_element.id).onmousedown = me.start_select_box.bind(me);
          $('annotation_holder_' + grid_element.id).style.cursor = 'crosshair';
        }
      })
    },
    set_annotation_grid: function(annot_grid){
        this.annotation_grid = annot_grid;
    },
    get_annotation_grid: function(){
        return this.annotation_grid;
    },
    //Get the coordinates of the mouse pointer relative to page
    //and return them in an array of the form [x, y].
    //Taken from http://www.quirksmode.org/js/events_properties.html#positions
    get_absolute_cursor_pos: function(e){
      var posx = 0;
      var posy = 0;
      if (!e) var e = window.event;
      if (e.pageX || e.pageY) {
              posx = e.pageX;
              posy = e.pageY;
      }
      else if (e.clientX || e.clientY) {
              posx = e.clientX + document.body.scrollLeft
                      + document.documentElement.scrollLeft;
              posy = e.clientY + document.body.scrollTop
                      + document.documentElement.scrollTop;
      }
      return [posx, posy];
    },
    //Start tracking the mouse to create an annotation.
    start_select_box: function(e){
      //Disable FireFox's default click and drag behaviour for images
      if(e.preventDefault) {
        e.preventDefault();
      }
      hide_image_annotations();
      var xy_coords = this.get_absolute_cursor_pos(e);
      var box = $("sel_box");
      var i;
      var annot_grid = this.get_annotation_grid();
      box.orig_x = xy_coords[0];
      box.orig_y = xy_coords[1];
      box.style.left = (xy_coords[0].toString()) + "px";
      box.style.top = (xy_coords[1].toString()) + "px";
      box.style.display = "block";
      $("image_preview").onmousemove = this.mouse_move.bind(this);
      $("image_preview").onmouseup = this.stop_select_box.bind(this);
      $("image_preview").onmousedown = null;

      box.onmousemove = this.mouse_move.bind(this);
      box.onmouseup = this.stop_select_box.bind(this);

      var me = this;
      annot_grid.each(function(grid_element) {
        $('annotation_holder_' + grid_element.id).onmousemove = me.mouse_move.bind(me);
        $('annotation_holder_' + grid_element.id).onmouseup = me.stop_select_box.bind(me);
        $('annotation_holder_' + grid_element.id).onmousedown = null;
      })
    },
    //Stop tracking the mouse and open up modal to create an image annotation.
    stop_select_box: function(e){
      var box = $("sel_box");
      var i;
      var annot_grid = this.get_annotation_grid();

      $("image_preview").onmousemove = this.check_for_annotations.bind(this);
      $("image_preview").onmouseup = null;
      $("image_preview").onmousedown = this.remove_select_box.bind(this);
      $("image_preview").onmousemove = null;

      box.onmousemove = null;
      box.onmouseup = null;

      var me = this;
      annot_grid.each(function(grid_element) {
        $('annotation_holder_' + grid_element.id).
          onmousemove = me.check_for_annotations.bind(me);
        $('annotation_holder_' + grid_element.id).
          onmousedown = me.start_select_box.bind(me);
        $('annotation_holder_' + grid_element.id).onmouseup = null;
      })
   },
    remove_select_box: function() {
      var box = $("sel_box");
      box.style.display = "none";
      box.style.width = "0";
      box.style.height = "0";
      $("image_preview").onmousedown = this.start_select_box.bind(this);
    }
    //Draw red selection outline
    , mouse_move: function(e) {
      var xy_coords = this.get_absolute_cursor_pos(e);
      var box = $("sel_box");
      if (xy_coords[0] >= box.orig_x){
        box.style.left = box.orig_x + "px";
        box.style.width = (xy_coords[0]-box.orig_x) + "px";
        //4th quadrant
        if (xy_coords[1] >= box.orig_y){
          box.style.top = (box.orig_y) + "px";
          box.style.height = (xy_coords[1]-box.orig_y) + "px";
        }
        //1st quadrant
        else{
          box.style.top = (xy_coords[1]) + "px";
          box.style.height = (box.orig_y - xy_coords[1]) + "px";
        }
      }
      else{
        box.style.left = (xy_coords[0]) + "px";
        box.style.width = (box.orig_x - xy_coords[0]) + "px";
        //3rd quadrant
        if (xy_coords[1] >= box.orig_y){
          box.style.top = (box.orig_y) + "px";
          box.style.height = (xy_coords[1]-box.orig_y) + "px";
        }
        //2nd quadrant
        else{
          box.style.top = (xy_coords[1]) + "px";
          box.style.height = (box.orig_y - xy_coords[1]) + "px";
        }
      }
    },
     check_for_annotations: function(e) {
      //Do not check for annotations until file completely loaded
      //Otherwise javascript throws a lot of unnoticable exceptions, as
      //annotation_manager gets loaded last.
      if (this.get_annotation_grid == null || annotation_manager == null){
        return;
      }
      var abs_xy = this.get_absolute_cursor_pos(e);
      //xy coords relative to the image
      var xy_coords = [abs_xy[0] - $("image_preview").offsetLeft + $("image_container").scrollLeft, abs_xy[1] - $("image_preview").offsetTop + $("image_container").scrollTop]
      var annot_grid = this.get_annotation_grid();
      var annots_to_display = [];
      //Check if current mouse position is annotated
      annot_grid.each(function(grid_element) {
        if(grid_element.x_range.include(xy_coords[0])) {
          if(grid_element.y_range.include(xy_coords[1])){
            //Annotation found
            annots_to_display.push(grid_element.id);
          }
        }
      })
      if(annots_to_display.length > 0){
        annotation_manager.display_image_annotation(annots_to_display, abs_xy[0], abs_xy[1]);
      }
      else{
        //No annotation found
        hide_image_annotations();
      }
    }
})