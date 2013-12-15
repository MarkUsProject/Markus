var groups_tab_menu = null;
var students_tab_menu = null;

jQuery(document).ready(function() {
  groups_tab_menu = new Control.Tabs('groups_tabs');
  groups_tab_menu.setActiveTab('none');
  students_tab_menu = new Control.Tabs('students_tabs');
  students_tab_menu.setActiveTab('unassigned');
  groups_tab_menu.bind('change',function(new_container){
   filter(new_container.id);
  });
  students_tab_menu.bind('change',function(new_container){
   filter(new_container.id);
  });
});
