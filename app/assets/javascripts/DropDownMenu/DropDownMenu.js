/** Drop Down Menu Class
  *
  * Implements Drop Down Menu behaviour using a trigger_node (what is clicked to show the menu)
  * and the menu_node (a hidden element that appears when the trigger node is clicked).
  * The menu_node is automatically positioned beneath the trigger_node in the constructor.
  */

function DropDownMenu(trigger_node, menu_node) {
  this.trigger_node = trigger_node;
  this.menu_node = menu_node;
  $(this.menu_node).hide();

  // Set up the trigger_node click event
  var me = this;
  $(this.trigger_node).hover(function() {
    me.refreshPositions();
    me.show();
  });
}

DropDownMenu.prototype.refreshPositions = function() {
  // Get cumulative position offsets of trigger_node...
  var offset_left   = $(this.getTriggerNode())[0].getBoundingClientRect().left;
  var offset_height = $(this.getTriggerNode()).height();

  let panel = $('.react-tabs-panel-action-bar')[0].getBoundingClientRect();

  // Position menu node so that it's directly under the trigger node,
  // and hide it. (340px & 5px values are due to accommodating CSS ul.tags rules in _markus.scss)
  $(this.getMenuNode()).css({
    'position' : 'absolute',
    'left' : Math.min(0, panel.right - (offset_left + 340)),
    'top' : offset_height + 5,
    'zIndex': '10000'
  });
}

DropDownMenu.prototype.getTriggerNode = function() {
  return this.trigger_node;
}

DropDownMenu.prototype.setTriggerNode = function(trigger_node) {
  this.trigger_node = trigger_node;
}

DropDownMenu.prototype.getMenuNode = function() {
  return this.menu_node;
}

DropDownMenu.prototype.setMenuNode = function(menu_node) {
  this.menu_node = menu_node;
}

DropDownMenu.prototype.show = function() {
  $(this.menu_node).show();
}

DropDownMenu.prototype.hide = function() {
  $(this.menu_node).hide();
}

DropDownMenu.prototype.getRelatedTarget = function(event) {
  if (event.toElement) {
    return event.toElement;
  }
  if (event.relatedTarget) {
    return event.relatedTarget;
  }
  return null;
}
