function populate(json_data) {
  groupings_table.populate(json_data);
  groupings_table.render();
}

function populate_students(json_data) {
  students_table.populate(json_data);
  students_table.render();
}

function filter(filter_name) {
  document.getElementById('working').style.display = '';
  try {
    switch(filter_name) {
      case 'validated':
      case 'unvalidated':
        groupings_table.filter_only_by(filter_name).render();
        break;
      case 'assigned':
      case 'unassigned':
      case 'inactive':
        students_table.filter_only_by(filter_name).render();
        break;
      case 'students_none':
        students_table.clear_filters().render();
      default:
        groupings_table.clear_filters().render();
    }
  }
  catch (e) {
    alert(e);
  }
  document.getElementById('working').style.display = 'none';
}

function modify_student(student_json) {
  var student = JSON.parse(student_json);
  students_table.write_row(student.id, student);
  students_table.resort_rows().render();
}

function modify_grouping(grouping_json, focus_after) {
  var grouping = JSON.parse(grouping_json);
  groupings_table.write_row(grouping.id, grouping);
  groupings_table.resort_rows().render();

  if (focus_after) {
    groupings_table.focus_row(grouping.id);
  }
}

function modify_groupings(groupings_json) {
  var groupings = $H(JSON.parse(groupings_json));
  groupings.each(function(grouping_record) {
    groupings_table.write_row(grouping_record.key, grouping_record.value);
  });
  groupings_table.resort_rows().render();
}

function modify_students(students_json) {
  var students = $H(JSON.parse(students_json));
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
  document.getElementById('working').style.display = '';
}

function done_thinking() {
  document.getElementById('global_action_form').disabled = false;
  document.getElementById('working').style.display = 'none';
}

function press_on_enter(event, element_id) {
  event.preventDefault();

  if (event.keyCode == 13) {
    jQuery('#' + element_id).click();
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

function check_all(prefix, check) {
  var cbox = document.getElementsByTagName('INPUT');

  for (var i = 0; i < cbox.length; i++) {
    if (cbox[i].type == 'checkbox') {
      if (cbox[i].name.split('_')[0] == prefix) {
        if (check == true) {
          cbox[i].checked = true;
        } else {
          cbox[i].checked = null;
        }
      }
    }
  }
}
