function add_annotation_prompt(path) {

  var annotation_text = jQuery('#add_annotation_text #annotation_text_content');

  if (annotation_text.size()) {
    annotation_text.select();
    annotation_text.focus();
  } else {
    jQuery.ajax({
        url: path,
        type: 'GET'
      });
  }
}

function add_annotation_category(path) {

  var category_prompt = jQuery('#add_annotation_category_prompt');

  if (category_prompt.size()) {
    category_prompt.select();
    category_prompt.focus();
  } else {
    jQuery.ajax({
      url: path,
      type: 'GET'
    });
    var info = jQuery('#no_annotation_categories_info');
    if(info.size()) {
      info.hide();
    }
  }
}

jQuery(document).ready(function () {

  window.modal_upload = new ModalMarkus('#upload_dialog');
  window.modal_download = new ModalMarkus('#download_dialog');

});