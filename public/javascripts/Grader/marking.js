function focus_rubric_criterion(id) {
    if(selected_rubric_criterion_id != null) {
        hide_rubric_criterion(selected_rubric_criterion_id);
    }
    if (selected_rubric_criterion_id == id) {
        hide_rubric_criterion(id);
        selected_rubric_criterion_id = null;
    } else {
        show_rubric_criterion(id);
        selected_rubric_criterion_id = id;
    }
}

function hide_rubric_criterion(id) {
    $('rubric_criterion_inputs_' + id).hide();
    $('rubric_criterion_title_' + id).show();
    $('rubric_criterion_title_' + id + "_expand").innerHTML = "+ &nbsp;"
}

function show_rubric_criterion(id) {
    $('rubric_criterion_title_'+id+"_expand").innerHTML = "- &nbsp;"
    $('rubric_criterion_inputs_' + id).show();
}

function select_mark(mark_id, mark) {
  original_mark = $$('#mark_' + mark_id + '_table .rubric_criterion_level_selected').first()
  if (typeof(original_mark) != "undefined") {
    original_mark.removeClassName('rubric_criterion_level_selected');
  }
  $('mark_' + mark_id + '_' + mark).addClassName('rubric_criterion_level_selected');
}

function unselect_extra_mark() {
    if (selected_extra_mark_id != null) {
        hide_extra_mark(selected_extra_mark_id);
        selected_extra_mark_id = null;
    }
}

function focus_extra_mark(id) {
    if(selected_extra_mark_id != null) {
        hide_extra_mark(selected_extra_mark_id);
    }
    show_extra_mark(id);
    selected_extra_mark_id = id;
}

function hide_extra_mark(id) {
    //hide all the input boxes
    $('extra_mark_inputs_'+id+'_description').hide();
    $('extra_mark_inputs_'+id+'_mark').hide();
    $('extra_mark_'+id+'_delete').hide();
    $('extra_mark_title_'+id+'_description').show();
    $('extra_mark_title_'+id+'_mark').show();
    $('extra_mark_'+id).removeClassName('criterion_holder_selected')
}

function show_extra_mark(id) {
    $('extra_mark_inputs_'+id+'_description').show();
    $('extra_mark_inputs_'+id+'_mark').show();
    $('extra_mark_'+id+'_delete').show();
    $('extra_mark_title_'+id+'_description').hide();
    $('extra_mark_title_'+id+'_mark').hide();
    $('extra_mark_'+id).addClassName('criterion_holder_selected');
}

