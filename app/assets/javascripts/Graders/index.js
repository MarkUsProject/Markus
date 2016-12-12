jQuery(document).ready(function () {
  window.modal_upload   = jQuery('#upload_dialog').easyModal();
  window.modal_download = jQuery('#download_dialog').easyModal();
  window.modal_coverage = new ModalMarkus('#groups_coverage_dialog');
  window.modal_criteria = new ModalMarkus('#grader_criteria_dialog');
});
