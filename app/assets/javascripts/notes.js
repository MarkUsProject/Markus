/** Page-specific event handlers for notes/new.html.erb */

jQuery(document).ready(function() {
  jQuery('#noteable_type select').change(function() {
    document.getElementById('working').style.display = '';

    var params = {
      'noteable_type': this.value,
      'authenticity_token': AUTH_TOKEN
    };

    jQuery.ajax({
      url:      'noteable_object_selector',
      data:     params,
      type:     'POST'
    }).done(function(data) {
      document.getElementById('working').style.display = 'none';
    });
  });
});
