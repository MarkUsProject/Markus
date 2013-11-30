jQuery(document).ready(function(){}); 

  // changing the marking status
  new Form.Element.EventObserver('marking_state', function(element, value) {

    var url = element.readAttribute('data-action');

    var params = {
      'value': value || '',
      'authenticity_token': AUTH_TOKEN
    }

    new Ajax.Request(url, {
      asynchronous: true,
      evalScripts: true,
      parameters: params
    });
  });

  // releasing the grades, only available on the admin page
  var release = jquery('released')
  if (releas
  {
    new Form.Element.EventObserver(release, function(element, value) // how i can use it ?{

      var url = element.readAttribute('data-action');

      var params = {
        'value': value || '',
        'authenticity_token': AUTH_TOKEN
      }

      new Ajax.Request(url, {
        asynchronous: true,
        evalScripts: true,
        parameters: params,
        onSuccess: function(request) { window.onbeforeunload = null; }
      });
    });
  }

  /**
   * event handlers for the flexible criteria grades
   */
  $$('.mark_grade_input').each(function(item) {

    // prevent clicks from hiding the grade
    item.observe('click', function(event){
      event.stop();
    });

    new Form.Element.EventObserver(item, function(element, value) {

      var url = element.readAttribute('data-action');

      var params = {
        'mark': value || '',
        'authenticity_token': AUTH_TOKEN
      }

      new Ajax.Request(url, {
        asynchronous: true,
        evalScripts: true,
        parameters: params
      });
    });
  });
});

function focus_mark_criterion(id) {
  if(jquery('#mark_criterion_title_' + id + '_expand').hasClass('expanded')) {
    hide_criterion(id);
  } else {
    show_criterion(id);
  }
}

function hide_criterion(id) {
    jquery('#mark_criterion_inputs_' + id).hide();
    jquery('#mark_criterion_title_' + id).show();
    jquery('mark_criterion_title_' + id + "_expand").innerHTML = "+ &nbsp;"
    jquery('#mark_criterion_title_' + id + "_expand").removeClass('expanded');
}

function show_criterion(id) {
    jquery('mark_criterion_title_'+id+"_expand").innerHTML = "- &nbsp;"
    jquery('mark_criterion_inputs_' + id).show();
    jquery('mark_criterion_title_' + id + "_expand").addClass('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = jquery('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first()
  if (typeof(original_mark) != "undefined") {
    original_mark.removeClass('rubric_criterion_level_selected');
  }
  if (mark != null){
	jquery('mark_' + mark_id + '_' + mark).addClass('rubric_criterion_level_selected');
  }
}

function update_total_mark(total_mark) {
  jquery('current_mark_div').update(total_mark);
  jquery('current_total_mark_div').update(total_mark);
}
