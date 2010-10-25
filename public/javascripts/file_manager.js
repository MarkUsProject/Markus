  // add new row of input 
function injectFileInput() {
  var new_file_field = new Element('input', {type: 'file', name: 'new_files[]'});
  var new_file_field_row = new Element('tr');
  var new_file_field_input_column = new Element('td', {colspan: 4});
  
  var remove_new_file_input = new Element('input', {type: 'checkbox'});
  
  remove_new_file_input.observe('change', function(node) {
    $(new_file_field_row).remove();
  });
  
  var remove_new_file_field_column = new Element('td');
  remove_new_file_field_column.insert(remove_new_file_input);
  remove_new_file_field_column.addClassName('delete_row');
  
  new_file_field_input_column.insert(new_file_field);
  new_file_field_row.insert(new_file_field_input_column);
  new_file_field_row.insert(remove_new_file_field_column);
  
  $('add_file_tbody').insert( {top: new_file_field_row});
  new_file_field.focus();
}

function check_change_of_filename(file_name, new_file_name, file_input) {
  /* new_file_name may include device identifiers and other things */
  slash = new_file_name.lastIndexOf("/");
  if (slash != -1) {
    new_file_name = new_file_name.substring(slash);
  }
  if(file_name != new_file_name) {
    alert("You cannot replace " + file_name + " with " + new_file_name + ".  You must replace a file with a file with the same name.");
    $(file_input).setValue('');
  }

}

function populate(files_json){
  // var files = files_json.evalJSON();
  files_table.populate(files_json).render();

}
