/**
* page specific event handlers for notes/new.html.erb
*/
document.observe("dom:loaded", function() {

  new Form.Element.EventObserver('noteable_type', function(element, value) {

    params = {
      'noteable_type': value,
      'authenticity_token': AUTH_TOKEN
    }
    $('loading_selector').show();

    new Ajax.Request('/en/notes/noteable_object_selector', {
      asynchronous: true,
      evalScripts: true,
      onSuccess: function(request) {
        $('loading_selector').hide()
      },
      parameters: params
    });
  });
});