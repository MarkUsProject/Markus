// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var ModalMarkus = function (elem) {
  this.elem = elem;
  this.modal_dialog = jQuery(this.elem).dialog({
    autoOpen: false,
    resizable: false,
    modal: true,
    width: 'auto',
    dialogClass: 'no-close'
  });
};

ModalMarkus.prototype = {

  open: function () {
    this.modal_dialog.dialog('open');
  },

  close: function () {
    this.modal_dialog.dialog('close');
  }

};
