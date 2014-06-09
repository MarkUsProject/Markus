/* STYLE CLASS/ID VARIABLES */
var highlightClassName = 'groupHighlight';
var assignedClassName  = 'groupAssigned';
var activeTAClassName  = 'activeTA';

/* STATE VARIABLES */
var selectedGroups = [];
var selectedTA     = -1;

// Removes TA assignment visualization for ALL groupings
function clear_show_ta_assignment() {
  var els = document.getElementsByClassName('groupings_list_assigned_dark');
  Array.prototype.forEach.call(els, function(node) {
    node.classList.remove('groupings_list_assigned_dark');
  });
}

function show_ta_assignment(grouping_id) {
  document.getElementById('grouping_' + grouping_id).classList.add('groupings_list_assigned_dark');
}

function hide_ta_assignment(grouping_id) {
  document.getElementById('grouping_' + grouping_id).classList.remove('groupings_list_assigned_dark');
}

function grouping_is_not_assigned(grouping_id) {
  document.getElementById('grouping_' + grouping_id).classList.remove('groupings_list_assigned_light');
}

function grouping_is_assigned(grouping_id) {
  document.getElementById('grouping_' + grouping_id).classList.add('groupings_list_assigned_light');
}

function allow_assigning_unassigning() {
  document.getElementById('assign_ta_button').disabled = false;
  document.getElementById('unassign_ta_button').disabled = false;
}

function disallow_assigning_unassigning() {
  document.getElementById('assign_ta_button').disabled = true;
  document.getElementById('unassign_ta_button').disabled = true;
}

function this_ta_selected(ta_id) {
  return selectedTA == ta_id;
}

/* Called when the User selects a TA. Only one TA should be active at any given time. */
function toggle_ta(ta_id) {
  // 2 cases:
  //   A. Select a new TA; selectedTA != newTA
  //   B. Deselect TA; selectedTA == newTA

  var newTA = document.getElementById('ta_' + ta_id);

  if (selectedTA != ta_id) {
    // Case A
    allow_assigning_unassigning();

    // activeTA is a class because id contains the ta_id value
    var activeTA = document.getElementsByClassName('activeTA');

    // If a TA has already been selected, i.e. there is an active TA
    if (activeTA.length == 1) {
      activeTA[0].classList.remove(activeTAClassName);
    }

    newTA.classList.add(activeTAClassName);
    selectedTA = ta_id;
  } else {
    // Case B
    clear_show_ta_assignment();
    newTA.classList.remove(activeTAClassName);
    selectedTA = -1;
    disallow_assigning_unassigning();
  }
}

/* Called when a user clicks on a group. Give it a highlight colour to indicate selection. */
function focus_group(group_id) {
  var group = document.getElementById('grouping_' + group_id);

  if (group.classList.contains(highlightClassName)) {
    // Deselecting
    group.classList.remove(highlightClassName);
    removeSelected(group_id);
  } else {
    // Selecting
    group.classList.add(highlightClassName);
    selectedGroups.push(group_id);
  }
}

/* Helper method: removes the given group from the array of selected groups */
function removeSelected(group_id) {
  for (var i = 0; i < selectedGroups.length; ++i) {
    if (selectedGroups[i] == group_id) {
      selectedGroups.splice(i, 1);
    }
  }
}

/* Toggle the groups that have been assigned the given TA */
function toggleTA(ta_id) {

}

function assign_ta_to_students(input) {
  var params = {
    'ta_id': selectedTA,
    'selected_groups': selectedGroups.toJSON(),
    'authenticity_token':  encodeURIComponent(authenticity_token)
  };

  jQuery.ajax({
    url:   '/checkmark/ta_assignments/assign/',
    async: true,
    type:  'POST',
    data:  params
  }).done(function() {
    var ta = document.getElementById('ta_' + selectedTA);
    var countContainer = ta.childElements()[0];

    // Deselect the currentTA in preparation for next assignment
    ta.classList.remove(activeTAClassName);

    // Mark the groups as assigned
    for (var i = 0; i < selectedGroups.length; i++) {
      var group = document.getElementById('grouping_' + selectedGroups[i]);
      group.classList.remove(highlightClassName);
      group.classList.add(assignedClassName);
      countContainer.innerHTML = (parseInt(countContainer.innerHTML) + 1);
    }

    selectedGroups = [];
    selectedTA = -1;
  }).fail(function() {
    alert('Server communications failure: this value was not updated.');
  });
}
