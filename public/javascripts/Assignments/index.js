
document.observe("dom:loaded", function() {

  modalUpload = new Control.Modal($('upload_dialog'),
    {
      overlayOpacity: 0.5,
      className: 'modalUpload'
    });

  modalDownload = new Control.Modal($('download_dialog'),
    {
      overlayOpacity: 0.5,
      className: 'modalDownload'
    });
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
