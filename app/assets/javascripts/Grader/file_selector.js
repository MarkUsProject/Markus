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

function open_file(select_node_id) {
  load_submitted_file(select_node_id);
}

function open_submenu(dir_element) {
  dir_element.nextElementSibling.style.display = 'block';
  var siblings = dir_element.parentNode.parentNode.childNodes;
  for (i = 0; i < siblings.length; i++)
  {
    if (siblings[i].className == "nested-submenu" && siblings[i] != dir_element.parentNode)
    {
      var sibling_folder_contents = siblings[i].childNodes;

      for (j = 0; j < sibling_folder_contents.length; j++)
      {
        if (sibling_folder_contents[j].className == "nested-folder")
        {
          close_submenu_recursive(sibling_folder_contents[j]);
        }
      }
    }
  }
}

function close_submenu_recursive(dir_element) {
  dir_element.style.display = 'none';
  var children = dir_element.childNodes;
  for (i = 0; i < children.length; i++)
  {
    if (children[i].className == "nested-submenu")
    {
      var child_folder_contents = children[i].childNodes;

      for (j = 0; j < child_folder_contents.length; j++)
      {
        if (child_folder_contents[j].className == "nested-folder")
        {
          close_submenu_recursive(child_folder_contents[j]);
        }
      }
    }
  }
}

function test() {
  console.log("hey");
}


jQuery(document).ready(function() {
  bump_select('select_file_id', 0, 'back_button', 'next_button');
});




