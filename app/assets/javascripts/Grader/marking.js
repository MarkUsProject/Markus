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

  // Event handlers for the flexible criteria grades
  $('.mark_grade_input').each(function(index, input) {
    var mark_id = input.id.substr(5);

    // Prevent clicks from hiding the grade
    $(this).click(function(event) {
      event.preventDefault();
      return false;
    });

    $(this).change(function() {
      var params = {
        'mark': this.value || '',
        'authenticity_token': AUTH_TOKEN
      };

      $.ajax({
        url:  this.getAttribute('data-action'),
        type: 'POST',
        data: params,
        beforeSend: function () {
          document.getElementById('mark_verify_result_' + mark_id)
                  .style.display = 'none';
        },
        error: function(err) {
          var error_div = document.getElementById(
            'mark_verify_result_' + mark_id);
          error_div.style.display = '';
          error_div.innerHTML = err.responseText;
        },
        success: function(data) {
          var items = data.split(',');
          var mark = items[0];
          var subtotal = items[1];
          var total = items[2];
          var marked = items[3];
          var assigned = items[4];
          update_total_mark(total);
          update_bar(marked, assigned);
          document.getElementById('mark_' + mark_id + '_summary_mark_after_weight')
            .innerHTML = mark;
          document.getElementById('current_subtotal_div').innerHTML = subtotal;
        }
      });
    });
  });

  $('.mark_grade_input_checkbox').each(function(index, input) {
    var tokens = input.id.split('_');
    var mark_id = tokens[1];
    var yes_or_no_type = tokens[2];

    $(this).click(function(event) {
      var params = {
        'mark': this.value || '',
        'authenticity_token': AUTH_TOKEN
      };

      $.ajax({
        url: this.getAttribute('data-action'),
        type: 'POST',
        data: params,
        beforeSend: function() {
          document.getElementById('mark_verify_result_' + mark_id).style.display = 'none';
        },
        error: function(err) {
          var error_div = document.getElementById('mark_verify_result_' + mark_id);
          error_div.style.display = '';
          error_div.innerHTML = err.responseText;
        },
        success: function(data) {
          var items = data.split(',');
          var mark = items[0];
          var subtotal = items[1];
          var total = items[2];
          var marked = items[3];
          var assigned = items[4];
          update_total_mark(total);
          update_bar(marked, assigned);
          document.getElementById('mark_' + mark_id + '_summary_mark_after_weight').innerHTML = mark;
          document.getElementById('current_subtotal_div').innerHTML = subtotal;
          $('#mark_' + mark_id + '_' + yes_or_no_type).prop('checked', true);
          $('#mark_' + mark_id + '_' + (yes_or_no_type === 'yes' ? 'no' : 'yes')).prop('checked', false);
          $('#checkbox_radio_button_container_' + mark_id).html(mark);
        }
      });

      event.preventDefault();
      return false;
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

  // Handle the expand/collapse buttons
  $('#expand_all').click(function() {
    $('.mark_criterion_level_container').each(function() {
      show_criterion(parseInt(this.getAttribute('data-id'), 10), 'RubricCriterion');
    });
    $('.mark_grade_input').each(function () {
      show_criterion(parseInt(this.getAttribute('data-id'), 10), 'FlexibleCriterion');
    });
    $('.mark_grade_input_checkbox').each(function () {
      show_criterion(parseInt(this.getAttribute('data-id'), 10), 'CheckboxCriterion');
    });
  });

  $('#collapse_all').click(function() {
    $('.mark_criterion_level_container').each(function() {
      hide_criterion(parseInt(this.getAttribute('data-id'), 10), 'RubricCriterion');
    });
    $('.mark_grade_input').each(function () {
      hide_criterion(parseInt(this.getAttribute('data-id'), 10), 'FlexibleCriterion');
    });
    $('.mark_grade_input_checkbox').each(function () {
      hide_criterion(parseInt(this.getAttribute('data-id'), 10), 'CheckboxCriterion');
    });
  });

  $('#expand_unmarked').click(function() {
    $('.mark_criterion_level_container').each(function () {
      expand_unmarked(this, 'RubricCriterion');
    });
    $('.mark_grade_input').each(function () {
      expand_unmarked(this, 'FlexibleCriterion');
    });
    $('.mark_grade_input_checkbox_container').each(function () {
      expand_unmarked(this, 'CheckboxCriterion');
    });
  });

  // Handle showing old mark when mark is updated in remark for flexible criterion
  $('.mark_grade_input').keypress(function() {
    var criterion_id = parseInt(this.getAttribute('data-id'), 10);
    var mark_id = parseInt(this.getAttribute('data-mark'), 10);
    var old_mark_elem = document.getElementById('flexible_' + criterion_id + '_old_mark');
    var mark_elem =  document.getElementById('mark_' + mark_id);
    var old_mark = this.getAttribute('data-oldmark');

    if (old_mark != 'none') {
      old_mark_elem.innerHTML = '(Old Mark: ' + old_mark + ')';
      mark_elem.removeClass('not_remarked');
      mark_elem.addClass('remarked');
    }
  });

  // Handle showing old mark when mark is updated in remark for checkbox criterion
  $('.mark_checkbox input[type=radio]').change(function() {
    var criterion_id = parseInt(this.getAttribute('data-id'), 10);
    var mark_id = parseInt(this.getAttribute('data-mark'), 10);
    var old_mark_elem = document.getElementById('checkbox_' + criterion_id + '_old_mark');
    var mark_elems =  document.getElementsByName('mark_' + mark_id);
    var old_mark = this.getAttribute('data-oldmark');

    if (old_mark != 'none') {
      old_mark_elem.innerHTML = '(Old Mark: ' + old_mark + ')';
      for (var i = 0; i < mark_elems; i++) {
        mark_elems[i].removeClass('not_remarked');
        mark_elems[i].addClass('remarked');
      }
    }
  });

  $('.error, .notice, .warning').append(
    $('<a />', {
      text: 'hide',
      style: 'float: right;',
      onclick: '$(this).parent().hide()'
    })
  );

  // Capture the mouse event to add "active-criterion" to the clicked element
  $(document).on('click', '.rubric_criterion, .flexible_criterion, .checkbox_criterion', function(e) {
    if (!$(this).hasClass('unassigned')) {
      e.preventDefault();
      activeCriterion($(this));
    }
  });
});

function expand_unmarked(elem, criterion_class) {
  if (criterion_class == 'RubricCriterion') {
    if ($(elem).find('.rubric_criterion_level_selected').length == 0) {
      show_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    } else {
      hide_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    }
  } else if (criterion_class == 'FlexibleCriterion') {
    if (elem.value == '') {
      show_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    } else {
      hide_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    }
  } else {
    var anyRadioButtonSet = $(elem).find('.mark_grade_input_checkbox:input:checked').length > 0;
    var hideOrShowCriterionFunc = anyRadioButtonSet ? hide_criterion : show_criterion;
    hideOrShowCriterionFunc(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
  }
}

// designate $next_criteria as the currently selected criteria
function activeCriterion($next_criteria) {
  if (!$next_criteria.hasClass('active-criterion')) {
    $criteria_list = $('#mark_criteria_pane_list>li');
    // remove all previous active-criterion (there should only be one)
    $criteria_list.removeClass('active-criterion');
    // scroll the $next_criteria to the top of the criterion bar
    $('#mark_viewer').animate({
      scrollTop: $next_criteria.offset().top - $criteria_list.first().offset().top
    }, 100);
    $next_criteria.addClass('active-criterion');
    // Unfocus any exisiting textfields/radio buttons
    $('.mark_grade_input, .mark_grade_input_checkbox').blur();
    // Remove any active rubrics
    $('.active-rubric').removeClass('active-rubric');
    if ($next_criteria.hasClass('flexible_criterion')) {
      var $input = $next_criteria.find('.mark_grade_input');
      // This step is necessary for focusing the cursor at the end of input
      $input.focus().val($input.val());
    } else if ($next_criteria.hasClass('rubric_criterion')) {
      $selected = $next_criteria.find('.rubric_criterion_level_selected');
      if ($selected.length) {
        $selected.addClass('active-rubric');
      } else {
        $next_criteria.find('tr>td')[0].addClass('active-rubric');
      }
    } else if ($next_criteria.hasClass('checkbox_criterion')) {
      $next_criteria.find('.mark_grade_input_checkbox').focus();
    }
    // If this current criteria is not expanded, expand it
    if ($next_criteria.hasClass('not_expanded')) {
      if ($next_criteria.hasClass('rubric_criterion')) {
        $next_criteria.children('.criterion_title').click();
      } else {
        $next_criteria.find('.criterion_expand').click();
      }
    }
  }
}

// Hide the expansion of the current active-criterion
function hideActiveCriterion() {
  $active = $('.active-criterion');
  if ($active.hasClass('expanded')) {
    if ($active.hasClass('rubric_criterion')) {
      $active.children('.criterion_title').trigger('onclick');
    } else {
      $active.find('.criterion_expand').trigger('onclick');
    }
  }
}

// Set the active-criterion to the next sibling
function nextCriterion() {
  $next_criterion = $('.active-criterion').next('li:not(.unassigned)');
  // If no next criterion exists, loop back to the first one
  if (!$next_criterion.length) {
    $next_criterion = $('#mark_criteria_pane_list>li:not(.unassigned)').first();
  }
  activeCriterion($next_criterion);
}

// Set the active-criterion to the previous sibling
function prevCriterion() {
  $prev_criterion = $('.active-criterion').prev('li:not(.unassigned)');
  // If no previous criterion exists, loop back to the last one
  if (!$prev_criterion.length) {
    $prev_criterion = $('#mark_criteria_pane_list>li:not(.unassigned)').last();
  }
  activeCriterion($prev_criterion);
}

// NOTE: This function is only called by rubric/flexible, not checkbox.
// It should be upgraded to focus_mark_criterion_type() in the future.
function focus_mark_criterion(id) {
  if ($('#mark_criterion_' + id).length != 0) {
    if ($('#mark_criterion_' + id).hasClass('expanded')) {
      hide_criterion(id, 'RubricCriterion');
    } else {
      show_criterion(id, 'RubricCriterion');
    }
  } else {
    if ($('#flexible_criterion_' + id).hasClass('expanded')) {
      hide_criterion(id, 'FlexibleCriterion');
    } else {
      show_criterion(id, 'FlexibleCriterion');
    }
  }
}

// Handles the class name now instead of assuming it is of a certain type.
function focus_mark_criterion_type(id, class_name) {
  var criterionClassPrefix = 'mark';
  if (class_name == 'FlexibleCriterion') {
    criterionClassPrefix = 'flexible';
  } else if (class_name == 'CheckboxCriterion') {
    criterionClassPrefix = 'checkbox';
  }

  var node = $('#' + criterionClassPrefix + '_criterion_' + id);
  if (node.length != 0) {
    var showOrHideCriterion = node.hasClass('expanded') ? hide_criterion : show_criterion;
    showOrHideCriterion(id, class_name);
  }
}

function hide_criterion(id, criterion_class) {
  var nodeToHide = null;
  var criterionPrefix = 'mark';
  if (criterion_class === 'RubricCriterion') {
    nodeToHide = document.getElementById('mark_criterion_' + id);
  } else if (criterion_class === 'FlexibleCriterion') {
    nodeToHide = document.getElementById('flexible_criterion_' + id);
  } else {
    nodeToHide = document.getElementById('checkbox_criterion_' + id);
    criterionPrefix = 'checkbox';
  }

  document.getElementById(criterionPrefix + '_criterion_title_' + id + '_expand').innerHTML = '+ &nbsp;';

  if (nodeToHide !== null) {
    nodeToHide.removeClass('expanded');
    nodeToHide.addClass('not_expanded');
  }
}

function show_criterion(id, criterion_class) {
  var criterionPrefix = 'mark';
  var classAddRemovePrefix = 'mark';

  if (criterion_class == 'FlexibleCriterion') {
    // TODO - This should also set the criterionPrefix when we refactor the flexible HTML/CSS later.
    classAddRemovePrefix = 'flexible';
  } else if (criterion_class == 'CheckboxCriterion') {
    criterionPrefix = 'checkbox';
    classAddRemovePrefix = 'checkbox';
  }

  document.getElementById(criterionPrefix + '_criterion_title_' + id + '_expand').innerHTML = '- &nbsp;';
  document.getElementById(classAddRemovePrefix + '_criterion_' + id).removeClass('not_expanded');
  document.getElementById(classAddRemovePrefix + '_criterion_' + id).addClass('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = $('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first();

  if (typeof(original_mark) !== 'undefined') {
    original_mark.removeClass('rubric_criterion_level_selected');
    original_mark.addClass('rubric_criterion_level');
  }

  if (mark !== null) {
    var rubric_div = document.getElementById('mark_' + mark_id + '_' + mark);
    rubric_div.addClass('rubric_criterion_level_selected');
    rubric_div.removeClass('rubric_criterion_level');
  }
}

// Function for AJAX request for rubric levels
function update_rubric_mark(elem, mark_id, value) {
  $.ajax({
    url:  elem.getAttribute('data-action'),
    type: 'POST',
    data: {'authenticity_token': AUTH_TOKEN},
    success: function(data) {
      var items = data.split(',');
      var mark = items[0];
      var subtotal = items[1];
      var total = items[2];
      var marked = items[3];
      var assigned = items[4];
      select_mark(mark_id, value);
      update_total_mark(total);
      update_bar(marked, assigned);
      document.getElementById('mark_' + mark_id + '_summary_mark_after_weight')
        .innerHTML = mark;
      document.getElementById('current_subtotal_div').innerHTML = subtotal;
    }
  });
}

function update_total_mark(total_mark) {
  document.getElementById('current_mark_div').innerHTML       = total_mark;
  document.getElementById('current_total_mark_div').innerHTML = total_mark;
  hideActiveCriterion();
  nextCriterion();
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
