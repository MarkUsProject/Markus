var code_tab_menu = null;
var mark_tab_menu = null;

document.observe('dom:loaded', function() {
  mark_tab_menu = new Control.Tabs('mark_tabs');
  mark_tab_menu.setActiveTab('mark_viewer');
  code_tab_menu = new Control.Tabs('code_and_annotations_tabs');
  code_tab_menu.setActiveTab('code_holder');
});