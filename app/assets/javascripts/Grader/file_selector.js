function open_file(id, path, downloading) {
    if (downloading) {
        document.getElementById('file_id').value = id;
        document.getElementById('download_file_selector_dropdown_text').innerHTML = path;
    } else {
        load_submitted_file(id);
        document.getElementById('select_file_id').value = id;
        document.getElementById('file_selector_dropdown_text').innerHTML = path;
    }
}

function open_submenu(dir_element) {
  dir_element.nextElementSibling.style.display = 'block';
  // When opening a submenu, we want to close all currently open submenus 
  // that aren't part of this submenu's path.
  close_submenu_recursive(dir_element.parentNode.parentNode,
      dir_element.parentNode);
}

function close_submenu_recursive(dir_element, orig_dir_element) {
  var children = dir_element.childNodes;
  for (var i = 0; i < children.length; i++) {
    if (children[i].className === 'nested-submenu' &&
        children[i] !== orig_dir_element) {
      var child_folder_contents = children[i].childNodes;
      for (var j = 0; j < child_folder_contents.length; j++) {
        if (child_folder_contents[j].className === 'nested-folder' &&
            child_folder_contents[j].style.display !== 'none') {
          child_folder_contents[j].style.display = 'none';
          close_submenu_recursive(child_folder_contents[j], orig_dir_element);
        }
      }
    }
  }
}

jQuery(document).ready(function() {
  if (first_file_id !== null && first_file_path !== null) {
    // for code viewer
    open_file(first_file_id, first_file_path, false);
    // for download modal
    open_file(first_file_id, first_file_path, true);
  }
});
