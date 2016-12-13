var modalCreate,
    modalAddMember,
    modalNotesGroup,
    modalAssignmentGroupReUse = null;

jQuery(document).ready(function () {
  modal_upload   = jQuery('#upload_dialog').easyModal();
  modal_download = jQuery('#download_dialog').easyModal();
  jQuery('#uploadModal').on('click',function(){
    modal_upload.trigger('openModal');
  });
  jQuery('#downloadModal').on('click',function(){
    modal_download.trigger('openModal');
  });
  window.modal_rename   = new ModalMarkus('#rename_group_dialog');
  modalCreate               = new ModalMarkus('#create_group_dialog');
  modalNotesGroup           = new ModalMarkus('#notes_dialog');
  modalAssignmentGroupReUse = new ModalMarkus('#assignment_group_use_dialog');
});
