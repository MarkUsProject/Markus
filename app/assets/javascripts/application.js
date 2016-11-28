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
//= require smart_poll
//= require_tree ./ReactComponents


/** Modal windows, powered by jQuery.easyModal. */

function ModalMarkus(elem) {
  this.modal_dialog = jQuery(elem).easyModal({
    onOpen: function (myModal) {
     // wait for the modal to load
     setTimeout(function () {
       // search for elements that can receive text as input
       var inputs = jQuery(myModal).find('textarea, input:text');
       if (inputs.length > 0) {
         inputs[0].focus();
       }
     }, 200);
    },
    updateZIndexOnOpen: false
  });
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

jQuery(document).ajaxComplete(function(event, request) {
    var keys = ["notice", "warning", "success", "error"];
    var keysLength = keys.length;
    for (var i = 0; i < keysLength; i++){
        if (request.getResponseHeader('X-Message-'+keys[i])) {
            jQuery(".flash-"+keys[i]).show();
            jQuery(".flash-"+keys[i]).text(request.getResponseHeader('X-Message-'+keys[i]));
        }
    }
});