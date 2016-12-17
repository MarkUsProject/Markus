jQuery(document).ready(function () {
  new ModalMarkus('#upload_dialog', '#uploadModal');
  new ModalMarkus('#download_dialog', '#downloadModal');
  window.modal_coverage = new ModalMarkus('#groups_coverage_dialog');
  window.modal_criteria = new ModalMarkus('#grader_criteria_dialog');
});
