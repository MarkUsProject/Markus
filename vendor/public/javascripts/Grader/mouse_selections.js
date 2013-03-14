function get_anchor() {
  //TODO:  Get this to work for IE
  //alert(window.getSelection());
  return window.getSelection().anchorNode;
}

function get_focus() {
  //TODO:  Get this to work for IE
  return window.getSelection().focusNode;
}


