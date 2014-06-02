function populate(json_data) {
  groupings_table.populate(json_data);
  groupings_table.render();
}

function populate_students(json_data) {
  students_table.populate(json_data);
  students_table.render();
}

function filter(filter_name) {
  document.getElementById('loading_list').style.display = '';
  try {
    switch (filter_name) {
      case 'validated':
      case 'unvalidated':
        groupings_table.filter_only_by(filter_name).render();
        break;
      case 'assigned':
      case 'unassigned':
        students_table.filter_only_by(filter_name).render();
        break;
      case 'students_none':
        students_table.clear_filters().render();
      default:
        groupings_table.clear_filters().render();
    }
  } catch (e) {
    alert(e);
  }
  document.getElementById('loading_list').style.display = 'none';
}

function modify_student(student_json) {
  var student = student_json.evalJSON();
  students_table.write_row(student.id, student);
  students_table.resort_rows().render();
}

function modify_grouping(grouping_json, focus_after) {
  var grouping = grouping_json.evalJSON();
  groupings_table.write_row(grouping.id, grouping);
  groupings_table.resort_rows().render();
  if (focus_after) {
    groupings_table.focus_row(grouping.id);
  }
}

// TODO: switch to jQuery
function modify_groupings(groupings_json) {
  var groupings = $H(groupings_json.evalJSON());
  groupings.each(function(grouping_record) {
    groupings_table.write_row(grouping_record.key, grouping_record.value);
  });
  groupings_table.resort_rows().render();
}

function modify_students(students_json) {
  var students = $H(students_json.evalJSON());
  students.each(function(student_record) {
    students_table.write_row(student_record.key, student_record.value);
  });
  students_table.resort_rows().render();
}

function remove_groupings(grouping_ids_json) {
 var grouping_ids = $A(grouping_ids_json.evalJSON());
  grouping_ids.each(function(grouping_id) {
    groupings_table.remove_row(grouping_id);
  });
  groupings_table.resort_rows().render();
}

function thinking() {
  document.getElementById('global_action_form').disabled = true;
  document.getElementById('loading_list').style.display = '';
}

function done_thinking() {
  document.getElementById('global_action_form').disabled = false;
  document.getElementById('loading_list').style.display = 'none';
}

function press_on_enter(event, element_id) {
  if (event.keyCode == 13) {
    jQuery(element_id).click();
    return false;
  }
}

function stop_submit(event) {
  var eve = event || window.event;
  var keycode = eve.keyCode || eve.which;

  if (keycode == 13) {
    eve.cancelBubble = true;
    eve.returnValue = false;

    if (eve.stopPropagation) {
      eve.stopPropagation();
      eve.preventDefault();
    }
  }
}

function check_all (prefix, check) {
  cbox = document.getElementsByTagName('input');
  for (var i = 0; i < cbox.length; i++) {
    if (cbox[i].type == 'checkbox') {
      if (cbox[i].name.split('_')[0] == prefix) {
        cbox[i].checked = check;
      }
    }
  }
}
