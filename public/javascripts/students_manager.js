function populate(json_data) {
  students_table.populate(json_data);
  students_table.render();
}

function filter(filter_name) {
  $('loading_list').show();
  try {
    switch(filter_name) {
      case 'active':
      case 'inactive':
        students_table.filter_only_by(filter_name).render();  
        break;
      default:
        students_table.clear_filters().render();
    }
  }
  catch (e) {
    alert(e);
  }
  $('loading_list').hide();
}

function modify_students(students_json) {
  students_table.write_rows(students_json.evalJSON());
  students_table.resort_rows().render();
}

