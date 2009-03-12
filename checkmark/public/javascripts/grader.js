/* 
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */


function focus_criterion(id) {
    if(selected_criterion_id != null) {
        hide_criterion(selected_criterion_id);
    }
    if (selected_criterion_id == id) {
        hide_criterion(id);
        selected_criterion_id = null;
    } else {
        show_criterion(id);
        selected_criterion_id = id;
    }
}

function hide_criterion(id) {
    $('criterion_inputs_'+id).hide();
    $('criterion_title_'+id).show();
    //$('criterion_inputs_'+id).removeClassName('criterion_holder_selected');
    $('criterion_title_'+id+"_expand").innerHTML = "+ &nbsp;"
}

function show_criterion(id) {
    $('criterion_title_'+id+"_expand").innerHTML = "- &nbsp;"
    $('criterion_inputs_'+id).show();
    //$('criterion_inputs_'+id).addClassName('criterion_holder_selected');
}

document.observe('dom:loaded', function() {
var rubric_tab_menu = new Control.Tabs('rubric_tabs');
rubric_tab_menu.setActiveTab('rubric_viewer');
var code_tab_menu = new Control.Tabs('code_and_annotations_tabs');
code_tab_menu.setActiveTab('code_pane');
})
