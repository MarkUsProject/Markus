var groups_tab_menu = null;
var students_tab_menu = null;

document.observe('dom:loaded', function() {
  groups_tab_menu = new Control.Tabs('groups_tabs');
  groups_tab_menu.setActiveTab('none');
  students_tab_menu = new Control.Tabs('students_tabs');
  students_tab_menu.setActiveTab('unassigned');
  groups_tab_menu.observe('afterChange',function(new_container){
   filter(new_container.id);
  });
  students_tab_menu.observe('afterChange',function(new_container){
   filter(new_container.id);
  });
});