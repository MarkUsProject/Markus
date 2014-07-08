/** Page-specific event handlers for notes/new.html.erb */

document.observe("dom:loaded", function() {

  new Form.Element.EventObserver('noteable_type', function(element, value) {
    document.getElementById('working').style.display = '';

    params = {
      'noteable_type': value,
      'authenticity_token': AUTH_TOKEN
    }

    new Ajax.Request('/en/notes/noteable_object_selector', {
      asynchronous: true,
      evalScripts: true,
      onSuccess: function(request) {
        document.getElementById('working').style.display = 'none';
      },
      parameters: params
    });
  });
});
