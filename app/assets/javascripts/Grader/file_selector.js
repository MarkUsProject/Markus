function bump_select(select_node_id, bump_amount, back_button_id, next_button_id) {
  // var select_node = document.getElementById(select_node_id);
  // var back_button = document.getElementById(back_button_id);
  // var next_button = document.getElementById(next_button_id);

  // var node_num       = select_node.length;
  // var selected_index = select_node.selectedIndex;
  // var result         = selected_index + bump_amount;

  // next_button.disabled = (result == node_num - 1);
  // back_button.disabled = (result == 0);

  // if (result >= node_num || result < 0) {
  //   back_button.disabled = true;
  //   next_button.disabled = true;
  //   return false;
  // }

  // select_node.selectedIndex = result;
  // load_submitted_file(select_node.value);
}

function open_file(select_node_id, filename) {
  load_submitted_file(select_node_id);
  document.getElementById("file_selector_dropdown_text").innerHTML = filename;
}

function open_submenu(dir_element) {
  dir_element.nextElementSibling.style.display = 'block';
  // When opening a submenu, we want to close all currently open submenus 
  // that aren't part of this submenu's path.
  close_submenu_recursive(dir_element.parentNode.parentNode, dir_element.parentNode);
}

function close_submenu_recursive(dir_element, orig_dir_element) {
  var children = dir_element.childNodes;
  for (i = 0; i < children.length; i++)
  {
    if (children[i].className == "nested-submenu" && children[i] != orig_dir_element)
    {
      var child_folder_contents = children[i].childNodes;

      for (j = 0; j < child_folder_contents.length; j++)
      {
        if (child_folder_contents[j].className == "nested-folder")
        {
          child_folder_contents[j].style.display = 'none';
          close_submenu_recursive(child_folder_contents[j], orig_dir_element);
        }
      }
    }
  }
}

jQuery(document).ready(function() {
  if (first_file_to_load_id != null && first_file_to_load_name != null)
  {
    open_file(first_file_to_load_id, first_file_to_load_name);
  }
});




