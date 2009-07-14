function populate(json_data) {
  users_table.populate(json_data);
  users_table.render();
}

function filter(filter_name) {
  $('loading_list').show();
  try {
    switch(filter_name) {
      case 'active':
      case 'inactive':
        users_table.filter_only_by(filter_name).render();  
        break;
      default:
        users_table.clear_filters().render();
    }
  }
  catch (e) {
    alert(e);
  }
  $('loading_list').hide();
}

function modify_students(users_json) {
  users_table.write_rows(users_json.evalJSON());
  users_table.resort_rows().render();
}

