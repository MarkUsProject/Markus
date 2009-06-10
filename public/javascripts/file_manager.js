  // add new row of input 
function injectFileInput() {
  var new_file_field = new Element('input', {type: 'file', name: 'new_files[]'});
  var new_file_field_div = new Element('div', {class: 'new_file'});
  var remove_new_file_field = new Element('a', {href: 'javascript:void(0);'});
  remove_new_file_field.update('[remove]');
  remove_new_file_field.observe('click', function(node) {
    $(new_file_field_div).remove();
  });
  
  new_file_field_div.insert(new_file_field);
  new_file_field_div.insert(remove_new_file_field);
  $('new_files').insert( {bottom: new_file_field_div});
}

function check_change_of_filename(file_name, new_file_name, file_input) {
  if(file_name != new_file_name) {
    alert("You cannot replace " + file_name + " with " + new_file_name + ".  You must replace a file with a file with the same name.");
    $(file_input).setValue('');
  }
}
