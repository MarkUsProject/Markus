// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require prototype
//= require jquery
//= require jquery-ui
//= require jquery_ujs
//= require jquery.easyModal

function ModalMarkus(elem) {
  this.modal_dialog = jQuery(elem).easyModal();
}

ModalMarkus.prototype.open = function() {
  this.modal_dialog.trigger('openModal');
}

ModalMarkus.prototype.close = function() {
  this.modal_dialog.trigger('closeModal');
}
