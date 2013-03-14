/**  Drop Down Menu Class

Implements Drop Down Menu behaviour using a trigger_node (what is clicked to show the menu) and the menu_node (a hidden element that appears when the trigger node is clicked).

The menu_node is automatically positioned beneath the trigger_node in the constructor.
**/

var DropDownMenu = Class.create({
  initialize: function(trigger_node, menu_node) {
    this.trigger_node = trigger_node;
    this.menu_node = menu_node;
    $(this.menu_node).hide();

    //Set up the trigger_node click event
    var me = this;
    $(this.trigger_node).observe('click', function(event) {
      me.refreshPositions();
      me.show();
    });
    //Set up the trigger_node mouseout event
    $(this.trigger_node).observe('mouseout', function(event) {
      var menu_node = me.getMenuNode();
      var mouse_entered = me.getRelatedTarget(event);
      if(mouse_entered !== null && !mouse_entered.descendantOf(menu_node) && mouse_entered.tagName != "HTML") {
        me.hide();
      }
    });
  },

  refreshPositions: function() {
    //Get cumulative position offsets of trigger_node...
    var offset_left, offset_top, offset_height;
    offset_left = $(this.getTriggerNode()).cumulativeOffset()[0];
    offset_top = $(this.getTriggerNode()).cumulativeOffset()[1];
    offset_height = $(this.getTriggerNode()).getHeight();

    //Position menu node so that it's directly under the trigger node, and
    //hide it
    $(this.getMenuNode()).setStyle({
      position: 'absolute',
      left: offset_left + 'px',
      top: (offset_top + offset_height) + 'px',
      zIndex: 1
    });
  },

  getTriggerNode: function() {
    return this.trigger_node;
  },

  setTriggerNode: function(trigger_node) {
    this.trigger_node = trigger_node;
  },

  getMenuNode: function() {
    return this.menu_node;
  },

  setMenuNode: function(menu_node) {
    this.menu_node = menu_node;
  },

  show: function() {
    $(this.menu_node).show();
  },

  hide: function() {
    $(this.menu_node).hide();
  },

  getRelatedTarget: function(event) {
    if(event.toElement) {
      return event.toElement;
    }
    if(event.relatedTarget) {
      return event.relatedTarget;
    }
    return null;
  }
});
