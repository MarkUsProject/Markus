function annotation_prompt(path) {
  jQuery.ajax({
      url: path,
      type: 'GET'
    });
}

jQuery(document).ready(function () {

  window.modal_upload = new ModalMarkus('#upload_dialog');
  window.modal_download = new ModalMarkus('#download_dialog');

});