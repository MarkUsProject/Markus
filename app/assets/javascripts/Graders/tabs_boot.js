var groups_tab_menu = null;
var graders_tab_menu = null;

jQuery(document).ready(function() {
  groups_tab_menu = new Control.Tabs('groups_tabs');
  groups_tab_menu.setActiveTab('groups_table');
  graders_tab_menu = new Control.Tabs('graders_tabs');
 graders_tab_menu.setActiveTab('all');

  groups_tab_menu.bind('change',function(new_container){
    jQuery('#current_table').val(new_container.id);
    clear_all();
  });
  graders_tab_menu.bind('change',function(new_container){
   filter(new_container.id);
  });
});
