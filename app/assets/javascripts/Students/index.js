var modalNotesGroup = null;

$(document).ready(function () {
  new ModalMarkus('#upload_dialog', '#uploadModal');
  new ModalMarkus('#download_dialog', '#downloadModal');
  modalNotesGroup = new ModalMarkus('#notes_dialog');
});