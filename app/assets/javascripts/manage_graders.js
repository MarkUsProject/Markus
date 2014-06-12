/**
 * page specific event handlers for grader/index.html.erb
 */
document.observe("dom:loaded", function() {
// jQuery(document).ready(function () {

  new Form.Element.EventObserver('assign_criteria', function(element, value) {

    var value = value || false;
    var url = element.readAttribute('data-action');

    var params = {
      'value': value,
      'authenticity_token': AUTH_TOKEN
    }

    new Ajax.Request(url, {
      asynchronous: true,
      evalScripts: true,
      parameters: params
    })
  })

});

function populate(json_data) {
  groupings_table.populate(json_data);
  groupings_table.render();
}

function populate_graders(json_data) {
  graders_table.populate(json_data);
  graders_table.render();
}

function populate_criteria(json_data) {
  criteria_table.populate(json_data);
  criteria_table.render();
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
        graders_table.filter_only_by(filter_name).render();
        break;
      case 'graders_none':
        graders_table.clear_filters().render();
      default:
        groupings_table.clear_filters().render();
    }
  }
  catch (e) {
    alert(e);
  }
  document.getElementById('working').style.display = 'none';
}

function modify_grader(grader_json) {
  var grader = grader_json.evalJSON();
  graders_table.write_row(grader.id, grader);
  graders_table.resort_rows().render();
}

function modify_criterion(criterion_json) {
  var criterion = criterion_json.evalJSON();
  criteria_table.write_row(criterion.id, criterion);
  criteria_table.resort_rows().render();
}

function modify_grouping(grouping_json, focus_after) {
  var grouping = grouping_json.evalJSON();
  groupings_table.write_row(grouping.id, grouping);
  groupings_table.resort_rows().render();
  if(focus_after) {
    groupings_table.focus_row(grouping.id);
  }
}

function modify_groupings(groupings_json) {
  var groupings = $H(groupings_json.evalJSON());
  groupings.each(function(grouping_record) {
    groupings_table.write_row(grouping_record.key, grouping_record.value);
  });
  groupings_table.resort_rows().render();
}

function modify_graders(graders_json) {
  var graders = $H(graders_json.evalJSON());
  graders.each(function(grader_record) {
    graders_table.write_row(grader_record.key, grader_record.value);
  });
  graders_table.resort_rows().render();
}

function modify_criteria(criteria_json) {
  var criteria = $H(criteria_json.evalJSON());
  criteria.each(function(criterion_record) {
    criteria_table.write_row(criterion_record.key, criterion_record.value);
  });
  criteria_table.resort_rows().render();
}

function remove_groupings(grouping_ids_json) {
 var grouping_ids = $A(grouping_ids_json.evalJSON());
  grouping_ids.each(function(grouping_id) {
    groupings_table.remove_row(grouping_id);
  });
  groupings_table.resort_rows().render();
}

function thinking() {
  $('global_action_form').disable();
  document.getElementById('working').style.display = '';
}

function done_thinking() {
  $('global_action_form').enable();
  document.getElementById('working').style.display = 'none';
}

function press_on_enter(event, element_id) {
  if (event.keyCode == 13)
  {
    $(element_id).click();
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

function clear_all() {
  cbox=document.getElementsByTagName('INPUT');
  for (i=0; i<cbox.length; i++){
    if (cbox[i].name != 'assign_groups' && cbox[i].name != 'assign_criteria')
    cbox[i].checked = null;
  }
}

function check_all(container, check) {
  jQuery(container).find('.inline_checkbox').prop('checked', check);
}
