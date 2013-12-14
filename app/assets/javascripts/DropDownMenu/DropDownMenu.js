/** Drop Down Menu Class

Implements Drop Down Menu behaviour using a trigger_node (what is clicked to show the menu) and the menu_node (a hidden element that appears when the trigger node is clicked).

The menu_node is automatically positioned beneath the trigger_node in the constructor.
**/

var DropDownMenu = Class.create({
  initialize: function(trigger_node, menu_node) {
    this.trigger_node = trigger_node;
    this.menu_node = menu_node;
    jQuery(this.menu_node).hide();

    //Set up the trigger_node click event
    var me = this;
    jQuery(this.trigger_node).bind('click', function(event) {
      me.refreshPositions();
      me.show();
    });
    //Set up the trigger_node mouseout event
    jQuery(this.trigger_node).bind('mouseout', function(event) {
      var menu_node = me.getMenuNode();
      var mouse_entered = me.getRelatedTarget(event);
      if(mouse_entered !== null && !(jQuery(mouse_entered).closest(menu_node).length > 0) && mouse_entered.tagName != "HTML") {
        me.hide();
      }
    });
  },

  refreshPositions: function() {
    //Get cumulative position offsets of trigger_node...
    var offset_left, offset_top, offset_height;
    offset_left = jQuery(this.getTriggerNode()).offset()[0];
    offset_top = jQuery(this.getTriggerNode()).offset()[1];
    offset_height = jQuery(this.getTriggerNode()).height();

    //Position menu node so that it's directly under the trigger node, and
    //hide it
    jQuery(this.getMenuNode()).css({
      "position" : "absolute",
      "left" : "offset_left + 'px'",
      "top" : "(offset_top + offset_height) + 'px'",
      "zIndex": "1"
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
    jQuery(this.menu_node).show();
  },

  hide: function() {
    jQuery(this.menu_node).hide();
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
