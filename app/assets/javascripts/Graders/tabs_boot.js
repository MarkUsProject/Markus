var groups_tab_menu = null;
var graders_tab_menu = null;

document.observe('dom:loaded', function() {
  groups_tab_menu = new Control.Tabs('groups_tabs');
  groups_tab_menu.setActiveTab('groups_table');
  graders_tab_menu = new Control.Tabs('graders_tabs');
 graders_tab_menu.setActiveTab('all');
  groups_tab_menu.observe('afterChange',function(new_container){
    $('current_table').value = new_container.id;
    clear_all();
  });
  graders_tab_menu.observe('afterChange',function(new_container){
   filter(new_container.id);
  });
});