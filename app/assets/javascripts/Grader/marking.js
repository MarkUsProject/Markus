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
          document.getElementById('mark_' + mark_id + '_summary_mark')
                  .innerHTML = mark;
          document.getElementById('current_subtotal_div').innerHTML = subtotal;
        }
      });
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
      if (jQuery(this).attr('data-scheme') == 'rubric') {
        show_rubric_criterion(this, parseInt(this.getAttribute('data-id'), 10));
      } else {
        show_flexible_criterion(parseInt(this.getAttribute('data-id'), 10));
      }
    });
  });

  jQuery('#collapse_all').click(function() {
    jQuery('.mark_criterion_level_container').each(function() {
      if (jQuery(this).attr('data-scheme') == 'rubric') {
          hide_rubric_criterion(this, parseInt(this.getAttribute('data-id'), 10));
      } else {
          hide_flexible_criterion(parseInt(this.getAttribute('data-id'), 10));
      }
    });
  });

  jQuery('#expand_unmarked').click(function() {
    jQuery('.mark_criterion_level_container').each(function () {
      if (jQuery(this).attr('data-scheme') == 'rubric') {
        expand_rubric_unmarked(this);
      } else {
        jQuery('.mark_grade_input').each(function () {
          expand_flexible_unmarked(this);
        });
      }
    });
  });
});

function expand_rubric_unmarked(elem) {
  if (jQuery(elem).find('.rubric_criterion_level_selected').length == 0) {
    show_rubric_criterion(elem, parseInt(elem.getAttribute('data-id'), 10));
  } else {
    hide_rubric_criterion(elem, parseInt(elem.getAttribute('data-id'), 10));
  }
};

function expand_flexible_unmarked(elem) {
  if (elem.value == '') {
    show_flexible_criterion(parseInt(elem.getAttribute('data-id'), 10));
  } else {
    hide_flexible_criterion(parseInt(elem.getAttribute('data-id'), 10));
  }
};

function focus_rubric_mark_criterion(id) {
  var elem = document.getElementById('criterion_info_' + id);
  if (jQuery('#mark_criterion_title_' + id + '_expand').hasClass('expanded')) {
    hide_rubric_criterion(elem, id);
  } else {
    show_rubric_criterion(elem, id);
  }
};

function focus_flexible_mark_criterion(id) {
  if (jQuery('#mark_criterion_title_' + id + '_expand').hasClass('expanded')) {
    hide_flexible_criterion(id);
  } else {
    show_flexible_criterion(id);
  }
};

function hide_rubric_criterion(table, id) {
  jQuery(table).find('.rubric_criterion_level').each(function() {
    jQuery(this).hide();
  });
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '+ &nbsp;';
  document.getElementById('mark_criterion_title_' + id + '_expand').removeClass('expanded');
};

function show_rubric_criterion(table, id) {
  jQuery(table).find('.rubric_criterion_level').each(function() {
    jQuery(this).show();
  });
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '- &nbsp;';
  document.getElementById('mark_criterion_title_' + id + '_expand').addClass('expanded');
};

function hide_flexible_criterion(id) {
  jQuery('#mark_criterion_title_' + id + '_mark').removeClass('mark_description');
  document.getElementById('criterion_info_' + id).style.display = 'none';
  document.getElementById('mark_criterion_title_' + id).style.display = '';
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '+ &nbsp;';
  document.getElementById('mark_criterion_title_' + id + '_expand').removeClass('expanded');
}

function show_flexible_criterion(id) {
  jQuery('#mark_criterion_title_' + id + '_mark').addClass('mark_description');
  document.getElementById('mark_criterion_title_' + id + '_expand').innerHTML = '- &nbsp;';
  document.getElementById('criterion_info_' + id).style.display = '';
  document.getElementById('mark_criterion_title_' + id + '_expand').addClass('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = jQuery('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first();

  if (typeof(original_mark) !== 'undefined') {
    original_mark.removeClass('rubric_criterion_level_selected');
  }

  if (mark !== null) {
    var rubric_div = document.getElementById('mark_' + mark_id + '_' + mark);
    rubric_div.addClass('rubric_criterion_level_selected');
    rubric_div.removeClass('rubric_criterion_level');
    jQuery(rubric_div).show();
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

      document.getElementById('mark_' + mark_id + '_summary_mark')
              .innerHTML = value;
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
