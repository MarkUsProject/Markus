var code_tab_menu = null;
var rubric_tab_menu = null;

document.observe('dom:loaded', function() {
  rubric_tab_menu = new Control.Tabs('rubric_tabs');
  rubric_tab_menu.setActiveTab('rubric_viewer');
  code_tab_menu = new Control.Tabs('code_and_annotations_tabs');
  code_tab_menu.setActiveTab('code_holder');

Ajax.Responders.register({
  onCreate: function() {
    $('working').show();
  },
  onComplete: function() {
    $('working').hide();
  }
});


});
