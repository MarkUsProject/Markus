jQuery(document).ready(function () {
  modal_upload   = jQuery('#upload_dialog').easyModal();
  modal_download = jQuery('#download_dialog').easyModal();
  jQuery('#uploadModal').on('click',function(){
    modal_upload.trigger('openModal');
  });
  jQuery('#downloadModal').on('click',function(){
    modal_download.trigger('openModal');
  });
  });

function choose_upload(value) {
  document.getElementById('file_format').value = value;
}

function toggleElem(id) {
  var elem = document.getElementById(id);
  var elem_display = elem.style.display;

  elem.style.display = (elem_display == 'none') ? 'block' : 'none';
}
