var modalNotesGroup = null;

jQuery(document).ready(function () {
  window.modal_download = new ModalMarkus('#download_dialog');
  window.modal_upload   = new ModalMarkus('#upload_dialog');
  modalNotesGroup = new ModalMarkus('#notes_dialog');
});
