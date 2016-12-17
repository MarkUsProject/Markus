jQuery(document).ready(function () {
  modal_upload   = jQuery('#upload_dialog').easyModal();
  modal_download = jQuery('#download_dialog').easyModal();
  jQuery('#uploadModal').on('click',function(){
    modal_upload.trigger('openModal');
  });
  jQuery('#downloadModal').on('click',function(){
    modal_download.trigger('openModal');
  });
  window.modal_coverage = new ModalMarkus('#groups_coverage_dialog');
  window.modal_criteria = new ModalMarkus('#grader_criteria_dialog');
});
