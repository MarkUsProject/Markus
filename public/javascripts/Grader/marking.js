function focus_mark_criterion(id) {
  if($('mark_criterion_title_' + id + '_expand').hasClassName('expanded')) {
    hide_criterion(id);
  } else {
    show_criterion(id);
  }
}

function hide_criterion(id) {
    $('mark_criterion_inputs_' + id).hide();
    $('mark_criterion_title_' + id).show();
    $('mark_criterion_title_' + id + "_expand").innerHTML = "+ &nbsp;"
    $('mark_criterion_title_' + id + "_expand").removeClassName('expanded');
}

function show_criterion(id) {
    $('mark_criterion_title_'+id+"_expand").innerHTML = "- &nbsp;"
    $('mark_criterion_inputs_' + id).show();
    $('mark_criterion_title_' + id + "_expand").addClassName('expanded');
}

function select_mark(mark_id, mark) {
  original_mark = $$('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first()
  if (typeof(original_mark) != "undefined") {
    original_mark.removeClassName('rubric_criterion_level_selected');
  }
  if (mark != null){
	$('mark_' + mark_id + '_' + mark).addClassName('rubric_criterion_level_selected');
  }
}

function update_total_mark(total_mark) {
  $('current_mark_div').update(total_mark);
  $('current_total_mark_div').update(total_mark);
}
