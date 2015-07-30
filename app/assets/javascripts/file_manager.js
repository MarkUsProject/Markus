/*
  new_file_field.change(function() {
    sanitized_filename_check(this);
    var fileCount = 0;
    var notTerminate = true;
    while (fileCount<this.files.length && notTerminate){
      if (this.files[fileCount].size > 3*1024*1024){
        if (!confirm('Warning, ' + this.files[fileCount].name +
            ' is ' + this.files[fileCount].size + ' bytes.' +
            ' Loading it in the web viewer may take a long time.' +
            ' Do you wish to proceed?')){
          // clear recently added file and terminate loop
          jQuery(this).val('');
          notTerminate = false;
        }
      }
    }

    return false;
  });
*/

jQuery(document).ready(function (){
  window.modal_addnew = new ModalMarkus('#addnew_dialog');
});

function submitFile(e) {
  e.submit();
}

function enableDisableSubmit() {
  var hasRows = false;

  jQuery('tbody').each(function(i) {
    var oRows = this.getElementsByTagName('tr');
    var iRowCount = oRows.length;
    if (iRowCount > 0) {
      hasRows = true;
    }
  });

  jQuery('#submit_form input[type=submit]').each(function(i) {
    jQuery(this).find('input, textarea').each(function(i) {
      if (hasRows) {
        jQuery(this).removeAttr('readonly');
      } else {
        jQuery(this).attr('readonly', 'readonly');
      }
    });
  });
}

function populate(files_json) {
  files_table.populate(files_json).render();
  enableDisableSubmit();
}
