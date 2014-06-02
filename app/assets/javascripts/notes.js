/** Page-specific event handlers for notes/new.html.erb */

jQuery(document).ready(function() {
  jQuery('#noteable_type').change(function() {
    var path = '/en/notes/noteable_object_selector';
    var params = {
      'noteable_type': this.value,
      'authenticity_token': AUTH_TOKEN
    }
    document.getElementById('loading_selector').style.display = '';

    jQuery.ajax({
      url: path,
      type: 'POST',
      async: true,
      data: params
    }).done(function() {
      document.getElementById('loading_selector').style.display = 'none';
    });
  });
});
