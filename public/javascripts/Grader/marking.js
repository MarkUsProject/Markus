function focus_rubric_criterion(id) {
  if($('rubric_criterion_title_' + id + '_expand').hasClassName('expanded')) {
    hide_rubric_criterion(id);
  } else {
    show_rubric_criterion(id);
  }
}

function hide_rubric_criterion(id) {
    $('rubric_criterion_inputs_' + id).hide();
    $('rubric_criterion_title_' + id).show();
    $('rubric_criterion_title_' + id + "_expand").innerHTML = "+ &nbsp;"
    $('rubric_criterion_title_' + id + "_expand").removeClassName('expanded');
}

function show_rubric_criterion(id) {
    $('rubric_criterion_title_'+id+"_expand").innerHTML = "- &nbsp;"
    $('rubric_criterion_inputs_' + id).show();
    $('rubric_criterion_title_' + id + "_expand").addClassName('expanded');
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
