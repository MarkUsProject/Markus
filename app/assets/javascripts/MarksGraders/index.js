var modalCreate,
    modalAssignmentGroupReUse,
    modalRenameGroup,
    modalAddMember,
    modalNotesGroup,
    modal_download,
    modal_download = null;
jQuery(document).ready(function() {
  modal_upload   = jQuery('#upload_dialog').easyModal();
  modal_download = jQuery('#download_dialog').easyModal();
  jQuery('#uploadModal').on('click',function(){
    modal_upload.trigger('openModal');
  });
  jQuery('#downloadModal').on('click',function(){
    modal_download.trigger('openModal');
  });
});