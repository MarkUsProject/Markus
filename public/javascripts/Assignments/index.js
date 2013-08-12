
jQuery(document).ready(function () {
  window.modal_upload = new ModalMarkus('#upload_dialog');
  window.modal_download = new ModalMarkus('#download_dialog');
});

function choose_upload(value) {
  $('file_format').value = value;
}

function toggleElem(val) {
  var elem = $(val);

  if (elem.style.display == 'none') {
    elem.style.display = 'block'
  } else {
    elem.style.display = 'none'
  }
}
