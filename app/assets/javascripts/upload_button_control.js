function _get(param_name){
  // Gets the correct attribute from the script.
  var scriptElement = document.getElementById('upload_script');

  // Now creates an array with each element.
  return scriptElement.getAttribute(param_name).split(" ");
}

jQuery(document).ready(function(){
  // First, gets the upload id and user id.
  var upload_id = _get('upload_id');
  var button_id = _get('button_id');

  // Checks to see if the file upload id changed.
  jQuery("input#" + upload_id).change(function () {
    var filePath = jQuery(this).val();

    var i;
    // Enables/Disables all buttons.
    for (i = 0; i < button_id.size(); i++) {
      // Either disables or enables upload buttons.
      if (filePath === "") {
        document.getElementById(button_id[i]).disabled = true;
      } else {
        document.getElementById(button_id[i]).disabled = false;
      }
    }
})});
