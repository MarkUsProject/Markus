// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

function hide_old_marks() {
  document.getElementById('old_summary_criteria_pane').style.display = 'none';
  document.getElementById('summary_criteria_pane').style.display = 'block';
}

function show_old_marks() {
  document.getElementById('old_summary_criteria_pane').style.display = 'block';
  document.getElementById('summary_criteria_pane').style.display = 'none';
}
