function filter(filter_name) {
  $('loading_list').show();
  try {
    switch(filter_name) {
      case 'validated':
      case 'unvalidated':
      case 'assigned':
      case 'unassigned':
        groupings_table.filter_only_by(filter_name).render();  
        break;
      default:
        groupings_table.clear_filters().render();
    }
  }
  catch (e) {
    alert(e);
  }
  $('loading_list').hide();
}

function modify_groupings(groupings_json) {
  var groupings = $H(groupings_json.evalJSON());
  groupings.each(function(grouping_record) {
    groupings_table.write_row(grouping_record.key, grouping_record.value);
  });
  groupings_table.resort_rows().render();
}

function remove_groupings(grouping_ids_json) {
 var grouping_ids = $A(grouping_ids_json.evalJSON());
  grouping_ids.each(function(grouping_id) {
    groupings_table.remove_row(grouping_id);
  });
  groupings_table.resort_rows().render();
}
