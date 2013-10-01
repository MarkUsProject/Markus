  // add new row of input 
function injectFileInput() {
  var new_file_field = new Element('input', {type: 'file',
                    name: 'new_files[]',
                    onchange: 'sanitized_filename_check(this); return false;',
                    multiple: true});
  var new_file_field_row = new Element('tr');
  var new_file_field_input_column = new Element('td', {colspan: 4});
  
  var remove_new_file_input = new Element('input', {type: 'checkbox'});
  
  remove_new_file_input.observe('change', function(node) {
    $(new_file_field_row).remove();
    enableDisableSubmit();
  });
  
  var remove_new_file_field_column = new Element('td');
  remove_new_file_field_column.insert(remove_new_file_input);
  remove_new_file_field_column.addClassName('delete_row');
  
  new_file_field_input_column.insert(new_file_field);
  new_file_field_row.insert(new_file_field_input_column);
  new_file_field_row.insert(remove_new_file_field_column);
  
  $('add_file_tbody').insert( {top: new_file_field_row});
  new_file_field.focus();
  enableDisableSubmit();
}

function enableDisableSubmit() {
  var hasRows = false;
  $$('tbody').each(function(item) {  
      var oRows = item.getElementsByTagName('tr');
      var iRowCount = oRows.length; 
      if (iRowCount >0) {
          hasRows = true;
        }
    });
  if (hasRows) {
    $$('#submit_form input[type=submit]').each(function(item) { item.enable() } );
  } else {
    $$('#submit_form input[type=submit]').each(function(item) { item.disable() } ); 
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
