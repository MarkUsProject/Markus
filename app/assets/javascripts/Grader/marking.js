jQuery(document).ready(function() {
  // Changing the marking status
  jQuery('#marking_state').change(function() {
    update_status(this, this.value)
  });

  function update_status(element, value) {
    var params = {
      'value': value || '',
      'authenticity_token': AUTH_TOKEN
    }

    jQuery.ajax({
      url:  element.readAttribute('data-action'),
      type: 'POST',
      data: params
    });
  }

  // Releasing the grades, only available on the admin page
  jQuery('#released').change(function() {
    var params = {
      'value': this.checked || '',
      'authenticity_token': AUTH_TOKEN
    }

    jQuery.ajax({
      url:  this.readAttribute('data-action'),
      type: 'POST',
      data: params
    }).done(function() {
      onbeforeunload.window = null;
    });
  });

  // Event handlers for the flexible criteria grades
  jQuery('.mark_grade_input').each(function(index) {

    // Prevent clicks from hiding the grade
    jQuery(this).click(function(event) {
      event.preventDefault();
      return false;
    });

    jQuery(this).change(function() {
      var params = {
        'mark': this.value || '',
        'authenticity_token': AUTH_TOKEN
      }

      jQuery.ajax({
        url:  this.readAttribute('data-action'),
        type: 'POST',
        data: params
      });
    });
  });

  // Update server status
  var state = document.getElementById('marking_state');
  update_status(state, state.value);
});

function focus_mark_criterion(id) {
  if (jQuery('#mark_criterion_title_' + id + '_expand').hasClass('expanded')) {
    hide_criterion(id);
  } else {
    show_criterion(id);
  }
}

function hide_criterion(id) {
  document.getElementById('mark_criterion_inputs_' + id).style.display = 'none';
  document.getElementById('mark_criterion_title_' + id).style.display = '';
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '+ &nbsp;';
  document.getElementById('mark_criterion_title_' + id + '_expand').classList.remove('expanded');
}

function show_criterion(id) {
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '- &nbsp;';
  document.getElementById('mark_criterion_inputs_' + id).style.display = '';
  document.getElementById('mark_criterion_title_' + id + '_expand').classList.add('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = jQuery('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first();

  if (typeof(original_mark) !== 'undefined') {
    original_mark.removeClass('rubric_criterion_level_selected');
  }

  if (mark !== null) {
    document.getElementById('mark_' + mark_id + '_' + mark).classList.add('rubric_criterion_level_selected');
  }
}

function update_total_mark(total_mark) {
  document.getElementById('current_mark_div').innerHTML       = total_mark;
  document.getElementById('current_total_mark_div').innerHTML = total_mark;
}

function update_marking_state_selected(current_marking_state, new_marking_state) {
  document.getElementById('marking_state').value = new_marking_state;

  /* Update server state if error displayed or new state is different from server state */
  var error_message = document.getElementById('criterion_incomplete_error');
  if (error_message.style.display != 'none' || current_marking_state != new_marking_state) {
    error_message.style.display = 'none';
    jQuery.ready();
  }
}
