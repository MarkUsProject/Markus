function choose_upload(value) {
  document.getElementById('file_format').value = value;
}

function toggleElem(id) {
  var elem = document.getElementById(id);
  var elem_display = elem.style.display;

  elem.style.display = (elem_display == 'none') ? 'block' : 'none';
}
