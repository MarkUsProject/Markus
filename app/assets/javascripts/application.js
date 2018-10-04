// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery-ui
//= require js-routes

/** Helper functions for managing DOM elements' classes via pure JavaScript. */

Element.prototype.addClass = function(className) {
  if (this.classList)
    this.classList.add(className);
  else
    this.className += ' ' + className;
}

Element.prototype.removeClass = function(className) {
  if (this.classList)
    this.classList.remove(className);
  else
    this.className = this.className.replace(new RegExp('(^|\\b)' + className.split(' ').join('|') + '(\\b|$)', 'gi'), ' ');
}

Element.prototype.hasClass = function(className) {
  if (this.classList)
    return this.classList.contains(className);
  else
    return new RegExp('(^| )' + className + '( |$)', 'gi').test(this.className);
}

$(document).ajaxComplete(function(event, request) {
  var keys = ['notice', 'warning', 'success', 'error'];
  var keysLength = keys.length;
  var flashMessageList = [];
  var receive = false;
  for (var i = 0; i < keysLength; i++) {
    flashMessageList.push(request.getResponseHeader('X-Message-' + keys[i]));
    if (flashMessageList[i]) receive = true;
  }
  for (var i = 0; i < keysLength; i++) {
    var flashMessage = flashMessageList[i];
    if (flashMessage) {
      var messages = flashMessage.split(';');
      $('.' + keys[i]).empty();
      $('.' + keys[i]).append(
        '<a class="hide-flash" onclick="$(this).parent().hide()">&nbsp;</a>'
      );
      for (var j = 0; j < messages.length; j++) {
        $('.' + keys[i]).append('<p>' + messages[j] + '</p>');
      }
      $('.' + keys[i]).show();
    } else if (receive) {
      $('.' + keys[i]).empty();
    }
    if ($('.' + keys[i]).is(':empty')) {
      $('.' + keys[i]).hide()
    }
  }
});
