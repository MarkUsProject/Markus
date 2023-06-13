var modalCreate,
  modalNotesGroup,
  modalAssignmentGroupReUse = null;

document.addEventListener("DOMContentLoaded", function () {
  window.modal_rename = new ModalMarkus("#rename_group_dialog");
  modalCreate = new ModalMarkus("#create_group_dialog");
  modalNotesGroup = new ModalMarkus("#notes_dialog");
  modalAssignmentGroupReUse = new ModalMarkus("#assignment_group_use_dialog");
});
