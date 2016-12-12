jQuery(document).ready(function () {
    window.modal_upload   = jQuery('#upload_dialog').easyModal();
    window.modal_download = jQuery('#download_dialog').easyModal();
});

function choose_upload(value) {
  document.getElementById('file_format').value = value;
}

function toggleElem(id) {
  var elem = document.getElementById(id);
  var elem_display = elem.style.display;

  elem.style.display = (elem_display == 'none') ? 'block' : 'none';
}
