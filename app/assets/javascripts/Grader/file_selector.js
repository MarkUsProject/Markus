function bump_select(select_node_id, bump_amount, back_button_id, next_button_id) {
  var select_node = document.getElementById(select_node_id);
  var back_button = document.getElementById(back_button_id);
  var next_button = document.getElementById(next_button_id);

  var node_num       = select_node.length;
  var selected_index = select_node.selectedIndex;
  var result         = selected_index + bump_amount;

  next_button.disabled = (result == node_num - 1);
  back_button.disabled = (result == 0);

  if (result >= node_num || result < 0) {
    back_button.disabled = true;
    next_button.disabled = true;
    return false;
  }

  select_node.selectedIndex = result;
  load_submitted_file(select_node.value);
}

jQuery(document).ready(function() {
  bump_select('select_file_id', 0, 'back_button', 'next_button');
});
