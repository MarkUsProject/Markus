function annotation_prompt(path) {
  var prompt = jQuery('#annotation_text_content');
  if (prompt.size()) {
    prompt.select();
    prompt.focus();
  } else {
    jQuery.ajax({
      url: path,
      type: 'GET'
    });
  }
}