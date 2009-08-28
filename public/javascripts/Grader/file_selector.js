function bump_select(select_node, bump_amount) {
  var node_num = $(select_node).descendants().length;
  var selected_index = $(select_node).selectedIndex; //Work for IE?
  var result = selected_index + bump_amount;
  if(result >= node_num || result < 0) {
    return false;
  }
  $(select_node).selectedIndex = result;
  load_submitted_file($F(select_node));
}
