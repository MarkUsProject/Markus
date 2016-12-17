var modalCreate,
    modalAddMember,
    modalNotesGroup,
    modalAssignmentGroupReUse = null;

jQuery(document).ready(function () {
  new ModalMarkus('#upload_dialog', '#uploadModal');
  new ModalMarkus('#download_dialog', '#downloadModal');
  window.modal_rename   = new ModalMarkus('#rename_group_dialog');
  modalCreate               = new ModalMarkus('#create_group_dialog');
  modalNotesGroup           = new ModalMarkus('#notes_dialog');
  modalAssignmentGroupReUse = new ModalMarkus('#assignment_group_use_dialog');
});
