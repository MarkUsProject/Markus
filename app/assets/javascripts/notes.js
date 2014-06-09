/** Page-specific event handlers for notes/new.html.erb */

jQuery(document).ready(function() {
  jQuery('#noteable_type').change(function() {
    document.getElementById('loading_selector').style.display = '';

    var params = {
      'noteable_type': this.value,
      'authenticity_token': AUTH_TOKEN
    }

    jQuery.ajax({
      url: '/en/notes/noteable_object_selector',
      type: 'POST',
      async: true,
      data: params
    }).done(function() {
      document.getElementById('loading_selector').style.display = 'none';
    });
  });
});
