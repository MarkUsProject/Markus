/**  Resize Pane Class

**/

var ResizePane = Class.create({
  initialize: function(pane_node, handle_node) {
    this.pane_node = pane_node;
    this.handle_node = handle_node;
    this.handle_draggable = this.createDragger();
    this.init_pane_node_width = $(this.getPaneNode().getWidth());
    this.init_pane_node_parent_width = this.getPaneNode().up(0).getWidth();
    this.init_pane_node_height = $(this.getPaneNode()).getHeight();

    var offset = $(this.getPaneNode()).cumulativeOffset();
    this.init_pane_node_offset_left = offset[0];
    this.init_pane_node_offset_top = offset[1];

  },
  getPaneNode: function() {
    return this.pane_node;
  },
  getHandleNode: function() {
    return this.handle_node;
  },
  getInitPaneNodeWidth: function() {
    return this.init_pane_node_width;
  },
  getInitPaneNodeHeight: function() {
    return this.init_pane_node_height;
  },
  getInitPaneNodeOffsetLeft: function() {
    return this.init_pane_node_offset_left;
  },
  getInitPaneNodeOffsetTop: function() {
    return this.init_pane_node_offset_top;
  },
  getInitPaneNodeParentWidth: function() {
    return this.init_pane_node_parent_width;
  },
  createDragger: function() {
      //Set up the events for the pane and handle nodes
    var me = this;

    var dragger = new Draggable(this.getHandleNode(), {scroll: window, constraint: 'horizontal',
    onDrag: function(dragged, event) {
      if(event != null) { //Sometimes, event is null.  It happens.
        var delta = event.pointerX() - me.getInitPaneNodeWidth();
        var pointer_x = event.pointerX();
        me.getPaneNode().setStyle({width: (pointer_x - me.getInitPaneNodeOffsetLeft()) + 'px'});

        //The magic 65 in the next line...can't seem to figure out why, when I resize the pane,
        //that even when I only resize by 1 or 2 pixels, I get a scroll bar appearing at the
        //bottom of the pane.  This page 65 seems to correct that...yech.
        me.getPaneNode().up('div').setStyle({width: (me.getInitPaneNodeParentWidth() + delta) + 'px'});
      }
    }});
    $(this.getHandleNode()).observe('mouseup', function(event) {
      //Eliminate bug that would keep the 'left' value of the handle at -3...
      me.getHandleNode().setStyle({left: '0px'});
    });

    return dragger;
  }


});
