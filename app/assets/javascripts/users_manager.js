function populate(json_data) {
  users_table.populate(json_data);
  users_table.render();
}

function filter(filter_name) {
  document.getElementById('loading_list').style.display = '';
  try {
    switch (filter_name) {
      case 'active':
      case 'inactive':
        users_table.filter_only_by(filter_name).render();
        break;
      default:
        users_table.clear_filters().render();
    }
  } catch (e) {
    alert(e);
  }
  document.getElementById('loading_list').style.display = 'none';
}

function modify_students(users_json) {
  users_table.write_rows(users_json.evalJSON());
  users_table.resort_rows().render();
}

function detect_bulk_action_change() {
  var action = document.getElementById('bulk_action').value;
  if (action == 'give_grace_credits') {
    document.getElementById('grace_credit_input').style.display = '';
    document.getElementById('number_of_grace_credits').select()
                                                      .focus();
  } else {
    document.getElementById('grace_credit_input').style.display = 'none';
  }

  if (action == 'add_section') {
    document.getElementById('section_input').style.display = '';
    document.getElementById('section').select()
                                      .focus();
  } else {
    document.getElementById('section_input').style.display = 'none';
  }
}

