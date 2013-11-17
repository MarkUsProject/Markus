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

function detect_bulk_action_change() {
  if($F('bulk_action') == 'give_grace_credits') {
    $('grace_credit_input').show();
    $('number_of_grace_credits').select();
    $('number_of_grace_credits').focus();

  } else {
    $('grace_credit_input').hide();
  }

  if($F('bulk_action') == 'add_section') {
    $('section_input').show();
    $('section').select();
    $('section').focus();
  } else {
    $('section_input').hide();
  }
}

