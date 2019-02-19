$(document).ready(function() {
  /* Update the script name in the legend when the admin uploads a file */
  $('.upload_file').change(function () {
    $(this).closest('.settings_box').find('.file_name').text(this.value);
  });

  /* Disables form elements when Remove checkbox is checked */
  $(".remove_test_group" ).click(function() {
    if(this.checked) {
      $(this).closest(".settings_box").find(":input").not(this).attr('disabled', true);
    } else {
      $(this).closest(".settings_box").find(":input").attr('disabled', false);
    }
  });
});
