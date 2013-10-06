function bump_select(select_node, bump_amount, back_button, next_button) {
  var node_num = $(select_node).descendants().length;
  var selected_index = $(select_node).selectedIndex; //Work for IE?
  var result = selected_index + bump_amount;
  
  if (result == node_num -1){
  	next_button.disabled = true;
  }
  else{
  	next_button.disabled = false;
  }
  
  if (result == 0){
  	back_button.disabled = true;
  }
  else{
  	back_button.disabled = false;
  }
  
  if(result >= node_num || result < 0) {
  	back_button.disabled = true;
  	next_button.disabled = true;
    return false;
  }
  
  $(select_node).selectedIndex = result;
  load_submitted_file($F(select_node));
}
