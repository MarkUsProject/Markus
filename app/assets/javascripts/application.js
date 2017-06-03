// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.easyModal
//= require_tree ./ReactComponents
//= require js-routes


/** Modal windows, powered by jQuery.easyModal. */

function ModalMarkus(elem, openLink) {
  this.modal_dialog = $(elem).easyModal({
    onOpen: function (myModal) {
     // wait for the modal to load
     setTimeout(function () {
       // search for elements that can receive text as input
       var inputs = $(myModal).find('textarea, input:text');
       if (inputs.length > 0) {
         inputs[0].focus();
       }
     }, 200);
    },
    updateZIndexOnOpen: false
  });

  // If link is provided, bind its onclick to open this modal.
  if (openLink !== undefined) {
    $(openLink).click(function () {
      this.open();
    }.bind(this))
  }

  // Set callbacks for buttons to close the modal.
  this.modal_dialog.find('.make_div_clickable, [type=reset]').click(function () {
    this.close();
  }.bind(this));
}

ModalMarkus.prototype.open = function() {
  this.modal_dialog.trigger('openModal');
}

ModalMarkus.prototype.close = function() {
  this.modal_dialog.trigger('closeModal');
}


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
