var modal_upload    = null;
var modal_download  = null;
var modalNotesGroup = null;

jQuery(document).ready(function () {
  modal_upload    = new ModalMarkus('#upload_dialog');
  modal_download  = new ModalMarkus('#download_dialog');
  modalNotesGroup = new ModalMarkus('#notes_dialog');
});
