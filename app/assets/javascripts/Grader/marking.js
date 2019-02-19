$(document).ready(function() {
  // Maintain compact view if toggled on
  if (typeof(Storage) !== 'undefined' &&
    localStorage.getItem('compact_view') === 'on') {
    compact_view_toggle(true);
  }

  // Changing the marking status
  $('#marking_state').change(function() {
    update_status(this, this.value)
  });

  function update_status(element, value) {
    var params = {
      'value': value || '',
      'authenticity_token': AUTH_TOKEN
    };

    $.ajax({
      url:  element.getAttribute('data-action'),
      type: 'POST',
      data: params
    });
  }

  // Releasing the grades, only available on the admin page
  $('#released').change(function() {
    var params = {
      'value': this.checked || '',
      'authenticity_token': AUTH_TOKEN
    };

    $.ajax({
      url:  this.getAttribute('data-action'),
      type: 'POST',
      data: params
    }).done(function() {
      window.onbeforeunload = null;
    });
  });

  // Handle indenting in the new annotation textarea (2 spaces)
  $('#new_annotation_content').keydown(function(e) {
    var keyCode = e.keyCode || e.which;

    if (keyCode == 9) {
      e.preventDefault();
      var start = this.selectionStart;
      var end   = this.selectionEnd;

      // Add the 2 spaces
      this.value = this.value.substring(0, start)
                   + '  '
                   + this.value.substring(end);

      // Put caret in correct position
      this.selectionStart = this.selectionEnd = start + 2;
    }
  });

  $('.error, .notice, .warning').append(
    $('<a />', {
      text: 'hide',
      style: 'float: right;',
      onclick: '$(this).parent().hide()'
    })
  );
});

// designate $next_criteria as the currently selected criteria
function activeCriterion($next_criteria) {
  if (!$next_criteria.hasClass('active-criterion')) {
    $criteria_list = $('#result_criteria_list>li');
    // remove all previous active-criterion (there should only be one)
    $criteria_list.removeClass('active-criterion');
    // scroll the $next_criteria to the top of the criterion bar
    $('#mark_viewer').animate({
      scrollTop: $next_criteria.offset().top - $criteria_list.first().offset().top
    }, 100);
    $next_criteria.addClass('active-criterion');
    // Unfocus any exisiting textfields/radio buttons
    $('.flexible_criterion input, .checkbox_criterion input').blur();
    // Remove any active rubrics
    $('.active-rubric').removeClass('active-rubric');
    if ($next_criteria.hasClass('flexible_criterion')) {
      var $input = $next_criteria.find('.mark_grade_input');
      // This step is necessary for focusing the cursor at the end of input
      $input.focus().val($input.val());
    } else if ($next_criteria.hasClass('rubric_criterion')) {
      $selected = $next_criteria.find('.rubric-level.selected');
      if ($selected.length) {
        $selected.addClass('active-rubric');
      } else {
        $next_criteria.find('tr>td')[0].addClass('active-rubric');
      }
    } else if ($next_criteria.hasClass('checkbox_criterion')) {
      $selected_option = $next_criteria.find('input[checked]')[0];
      if ($selected_option) {
        $selected_option.focus();
      } else {
        $next_criteria.find('input')[0].focus();
      }
    }
    // If this current criteria is not expanded, expand it
    if (!$next_criteria.hasClass('expanded')) {
      if ($next_criteria.hasClass('rubric_criterion')) {
        $next_criteria.children('.criterion_title').click();
      } else {
        $next_criteria.find('.criterion_expand').click();
      }
    }
  }
}

// Set the active-criterion to the next sibling
function nextCriterion() {
  $next_criterion = $('.active-criterion').next('li:not(.unassigned)');
  // If no next criterion exists, loop back to the first one
  if (!$next_criterion.length) {
    $next_criterion = $('#result_criteria_list>li:not(.unassigned)').first();
  }
  activeCriterion($next_criterion);
}

// Set the active-criterion to the previous sibling
function prevCriterion() {
  $prev_criterion = $('.active-criterion').prev('li:not(.unassigned)');
  // If no previous criterion exists, loop back to the last one
  if (!$prev_criterion.length) {
    $prev_criterion = $('#result_criteria_list>li:not(.unassigned)').last();
  }
  activeCriterion($prev_criterion);
}

function update_total_mark(total_mark) {
  document.getElementById('current_mark_div').innerHTML       = total_mark;
  document.getElementById('current_total_mark_div').innerHTML = total_mark;
  // TODO: Enable this once it only moves to next *unmarked* criterion.
  // nextCriterion();
}

function compact_view_toggle(init) {
  var toggle_elements = [
    $('#menus'),
    $('.top_bar'),
    $('.title_bar'),
    $('#footer_wrapper')
  ];
  $.each(toggle_elements, function(idx, element){
    element.toggle();
  });
  $('#content').toggleClass('expanded_view');
  if (!init) {
    if (typeof(Storage) !== 'undefined') {
      var compact_view = localStorage.getItem('compact_view');
      if (compact_view) localStorage.removeItem('compact_view');
      else localStorage.setItem('compact_view', 'on');
    }
    fix_panes();
  }
}
