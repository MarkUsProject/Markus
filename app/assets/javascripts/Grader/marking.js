jQuery(document).ready(function(){}); 




('#buttonId').click(  
 function() {  
     // implement...  
 }  
);  

  // changing the marking status

  new jQuery('#marking_state').change( function(element, value) {

    var url = jQuery(this).attr('data-action');

    var params = {
      'value': value || '',
      'authenticity_token': AUTH_TOKEN
    }

    jQuery.ajax(
      asynchronous: true,
      evalScripts: true,
      parameters: params
    );
  });

  // releasing the grades, only available on the admin page
  var release = jQuery('released')
  if (release)
  {
    new jQuery('#release').change( function(element, value){
 
      var url = jQuery(this).attr('data-action');

      var params = {
        'value': value || '',
        'authenticity_token': AUTH_TOKEN
      }




	jQuery:
	jQuery.ajax({
	url:,	
	data:params,
	type:"POST"
	async: true,
	dataType:'json'
	}).success(function (data) {
	window.onbeforeunload = null;
	populate(JSON.stringify(data));
	});

    });
  }

  /**
   * event handlers for the flexible criteria grades
   */
  jQuery('.mark_grade_input').each(function(item) {

    // prevent clicks from hiding the grade
    item.observe('click', function(event){
      event.stopPropagation();
    });

    new jQuery('#item').change(function(element, value) {
       
      var url =jQuery(this).attr('data-action');

      var params = {
        'mark': value || '',
        'authenticity_token': AUTH_TOKEN
      }

      jQuery.ajax(
        asynchronous: true,
        evalScripts: true,
        parameters: params
      );
    });
  });
});

function focus_mark_criterion(id) {
  if(jQuery('#mark_criterion_title_' + id + '_expand').hasClass('expanded')) {
    hide_criterion(id);
  } else {
    show_criterion(id);
  }
}

function hide_criterion(id) {
    jQuery('#mark_criterion_inputs_' + id).hide();
    jQuery('#mark_criterion_title_' + id).show();
    jQuery('#mark_criterion_title_' + id + "_expand").html("+ &nbsp;");
    jQuery('#mark_criterion_title_' + id + "_expand").removeClass('expanded');
}

function show_criterion(id) {
    jQuery('#mark_criterion_title_'+id+"_expand").html("- &nbsp;");
    jQuery('#mark_criterion_inputs_' + id).show();
    jQuery('mark_criterion_title_' + id + "_expand").addClass('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = jQuery('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first()
  if (typeof(original_mark) != "undefined") {
    original_mark.removeClass('rubric_criterion_level_selected');
  }
  if (mark != null){
	jQuery('mark_' + mark_id + '_' + mark).addClass('rubric_criterion_level_selected');
  }
}

function update_total_mark(total_mark) {
  jQuery('#current_mark_div').html(total_mark);
  jQuery('#current_total_mark_div').html(total_mark);
}
