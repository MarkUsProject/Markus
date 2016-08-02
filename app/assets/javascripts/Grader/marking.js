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
      url:  element.getAttribute('data-action'),
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
      url:  this.getAttribute('data-action'),
      type: 'POST',
      data: params
    }).done(function() {
      window.onbeforeunload = null;
    });
  });

  // Event handlers for the flexible criteria grades
  jQuery('.mark_grade_input').each(function(index, input) {
    var mark_id = input.id.substr(5);

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
          update_total_mark(total);
          document.getElementById('mark_' + mark_id + '_summary_mark_after_weight')
            .innerHTML = mark;
          document.getElementById('current_subtotal_div').innerHTML = subtotal;
        }
      });
    });
  });

  // Event handlers for the checkbox criteria.
  jQuery('.mark_grade_input_checkbox').each(function(index, input) {
      var mark_id = input.id.substr(5);

      var checkboxElement = jQuery(this);
      checkboxElement.click(function(event) {
          var params = {
              'mark': this.value || '',
              'authenticity_token': AUTH_TOKEN
          };

          jQuery.ajax({
              url:  this.getAttribute('data-action'),
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
                  update_total_mark(total);
                  document.getElementById('mark_' + mark_id + '_summary_mark_after_weight').innerHTML = mark;
                  document.getElementById('current_subtotal_div').innerHTML = subtotal;
                  checkboxElement.prop('checked', parseFloat(mark) > 0.0);
              }
          });

          event.preventDefault();
          return false;
      });
  });

  // Handle indenting in the new annotation textarea (2 spaces)
  jQuery('#new_annotation_content').keydown(function(e) {
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
  })

  // Handle the expand/collapse buttons
  jQuery('#expand_all').click(function() {
    jQuery('.mark_criterion_level_container').each(function() {
      show_criterion(parseInt(this.getAttribute('data-id'), 10), 'RubricCriterion');
    });
    jQuery('.mark_grade_input').each(function () {
      show_criterion(parseInt(this.getAttribute('data-id'), 10), 'FlexibleCriterion');
    });
  });

  jQuery('#collapse_all').click(function() {
    jQuery('.mark_criterion_level_container').each(function() {
      hide_criterion(parseInt(this.getAttribute('data-id'), 10), 'RubricCriterion');
    });
    jQuery('.mark_grade_input').each(function () {
      hide_criterion(parseInt(this.getAttribute('data-id'), 10), 'FlexibleCriterion');
    });
  });

  jQuery('#expand_unmarked').click(function() {
    jQuery('.mark_criterion_level_container').each(function () {
      expand_unmarked(this, 'RubricCriterion');
    });
    jQuery('.mark_grade_input').each(function () {
      expand_unmarked(this, 'FlexibleCriterion');
    });
  });

  // Handle showing old mark when mark is updated in remark
  jQuery('.mark_grade_input').keypress(function() {
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
});

function expand_unmarked(elem, criterion_class) {
  if (criterion_class == 'RubricCriterion') {
    if (jQuery(elem).find('.rubric_criterion_level_selected').length == 0) {
      show_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    } else {
      hide_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    }
  } else {
    if (elem.value == '') {
      show_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    } else {
      hide_criterion(parseInt(elem.getAttribute('data-id'), 10), criterion_class);
    }
  }
};

function focus_mark_criterion(id) {
  if (jQuery('#mark_criterion_' + id).length != 0) {
    if (jQuery('#mark_criterion_' + id).hasClass('expanded')) {
      hide_criterion(id, 'RubricCriterion');
    } else {
      show_criterion(id, 'RubricCriterion');
    }
  } else {
    if (jQuery('#flexible_criterion_' + id).hasClass('expanded')) {
      hide_criterion(id, 'FlexibleCriterion');
    } else {
      show_criterion(id, 'FlexibleCriterion');
    }
  }
};

function hide_criterion(id, criterion_class) {
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '+ &nbsp;';
  if (criterion_class == 'RubricCriterion') {
    document.getElementById('mark_criterion_' + id).removeClass('expanded');
    document.getElementById('mark_criterion_' + id).addClass('not_expanded');
  } else if (criterion_class == 'FlexibleCriterion') {
    document.getElementById('flexible_criterion_' + id).removeClass('expanded');
    document.getElementById('flexible_criterion_' + id).addClass('not_expanded');
  } else {
    document.getElementById('checkbox_criterion_' + id).removeClass('expanded');
    document.getElementById('checkbox_criterion_' + id).addClass('not_expanded');
  }
};

function show_criterion(id, criterion_class) {
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '- &nbsp;';
  if (criterion_class == 'RubricCriterion') {
    document.getElementById('mark_criterion_' + id).removeClass('not_expanded');
    document.getElementById('mark_criterion_' + id).addClass('expanded');
  } else if (criterion_class == 'FlexibleCriterion') {
    document.getElementById('flexible_criterion_' + id).removeClass('not_expanded');
    document.getElementById('flexible_criterion_' + id).addClass('expanded');
  } else {
      document.getElementById('checkbox_criterion_' + id).removeClass('not_expanded');
      document.getElementById('checkbox_criterion_' + id).addClass('expanded');
  }
};

function select_mark(mark_id, mark) {
  original_mark = jQuery('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first();

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
  jQuery.ajax({
    url:  elem.getAttribute('data-action'),
    type: 'POST',
    data: {'authenticity_token': AUTH_TOKEN},
    success: function(data) {
      var items = data.split(',');
      var mark = items[0];
      var subtotal = items[1];
      var total = items[2];
      select_mark(mark_id, value);
      update_total_mark(total);
      document.getElementById('mark_' + mark_id + '_summary_mark_after_weight')
        .innerHTML = mark;
      document.getElementById('current_subtotal_div').innerHTML = subtotal;
    }
  });
}

function update_total_mark(total_mark) {
  document.getElementById('current_mark_div').innerHTML       = total_mark;
  document.getElementById('current_total_mark_div').innerHTML = total_mark;
}
