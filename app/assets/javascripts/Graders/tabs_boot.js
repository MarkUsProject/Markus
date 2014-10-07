jQuery(document).ready(function() {
  jQuery('#graders-tabs').tabs();
  jQuery('#groups-tabs').tabs({
    activate: function(event, ui) {
      var new_container_id =  ui.newPanel.get(0).id;
      document.getElementById('current_table').value = new_container_id;
    }
  });
});
