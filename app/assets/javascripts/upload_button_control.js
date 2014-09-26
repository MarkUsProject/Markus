function _get(param_name){
    // Gets the correct attribute from the script.
    var scriptElement = document.getElementById('upload_script');
    return scriptElement.getAttribute(param_name);
}

jQuery(document).ready(function(){
    // First, gets the upload id and user id.
    var upload_id = _get('upload_id');
    var button_id = _get('button_id');

    // Checks to see if the file upload id changed.
    jQuery("input#" + upload_id).change(function () {
        var filePath = jQuery(this).val();

        // Either disables or enables upload buttons.
        if (filePath === "") {
            document.getElementById(button_id).disabled = true;
        } else {
            document.getElementById(button_id).disabled = false;
        }
})});

