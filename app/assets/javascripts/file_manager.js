  // add new row of input
function injectFileInput() {
  var new_file_field = jQuery('<input>', {  
		type: 'file',
    name: 'new_files[]',
    multiple: true
  });  

	new_file_field.change(function() {
		sanitized_filename_check(this);
		return false;
	});


	var new_file_field_row = jQuery('<tr>');

  var new_file_field_input_column = jQuery('<td>', {colspan: 4});

  var remove_new_file_input = jQuery('<input>', {type: 'checkbox'});

	remove_new_file_input.change(function(node) {
    jQuery(new_file_field_row).remove();
    enableDisableSubmit();
  });

  var remove_new_file_field_column = jQuery('<td>');

  remove_new_file_field_column.append(remove_new_file_input);
  remove_new_file_field_column.addClass('delete_row');

  new_file_field_input_column.append(new_file_field);
  new_file_field_row.append(new_file_field_input_column);
  new_file_field_row.append(remove_new_file_field_column);

  jQuery('#add_file_tbody').prepend(new_file_field_row);
  new_file_field.focus();
  enableDisableSubmit();
}

function enableDisableSubmit() {
  var hasRows = false;
  jQuery('tbody').each(function(i) {
      var oRows = this.getElementsByTagName('tr');
      var iRowCount = oRows.length;
      if (iRowCount >0) {
          hasRows = true;
        }
    });
  if (hasRows) {
    jQuery('#submit_form input[type=submit]').each(function(i) {
  		jQuery(this).find('input, textarea').each(function(i) { jQuery(this).removeAttr("readonly"); });
		});
  } else {
    jQuery('#submit_form input[type=submit]').each(function(i) {
 		  jQuery(this).find('input, textarea').each(function(i) { jQuery(this).attr("readonly","readonly"); });
		});
  }
}
/*
 * Strip off some local file-path garbage potentially passed by the browser.
 * Called from app/views/submissions/_file_manager_boot.js.erb
 */
function normalize_filename(new_file_name) {
  /************************************************************************
   * Note: new_file_name may include device identifiers and may be preceded
   *       by the full path to the file on the user's local system.
   * Examples:
   *     C:\\data\\folder\\file.txt  // '\' is a special char in JS
   *     D:/data/school/program.py
   *     /home/user/Documents/Class.java
   *     core.c
   ***********************************************************************/
  // Unify path separator
  new_file_name = new_file_name.replace(/\\/g, "/");
  slash = new_file_name.lastIndexOf("/");
  if (slash != -1) {
    // Absolute path given, strip off preceding parts
    new_file_name = new_file_name.substring(slash + 1);
  }
  return new_file_name;
}

function populate(files_json){
  // var files = files_json.evalJSON();
  files_table.populate(files_json).render();
  enableDisableSubmit();
}
