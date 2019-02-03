function open_file(id, path, downloading) {
    if (downloading) {
        document.getElementById('file_id').value = id;
        document.getElementById('download_file_selector_dropdown_text').innerHTML = path;
    } else {
        localStorage.setItem('file_path', path);
        load_submitted_file(id);
    }
}

function open_submenu(dir_element) {
  dir_element.nextElementSibling.style.display = 'block';
  dir_element.nextElementSibling.style.top = $(dir_element).position().top + 'px';

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
