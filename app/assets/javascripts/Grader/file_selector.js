// Hamid est passé par là .......

function bump_select(select_node, bump_amount, back_button, next_button) {
  var node_num = jQuery('#select_node').descendants().length;
  var selected_index = jQuery('#select_node').selectedIndex; //Work for IE?
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
  
  jQuery('#select_node').selectedIndex = result;
  load_submitted_file(jQuery('#select_node').val();


}
