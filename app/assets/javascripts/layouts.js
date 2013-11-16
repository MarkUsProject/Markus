jQuery(document).ready(function () {

  window.role_switch_modal = new ModalMarkus('#role_switch_dialog');
  window.dialog_modal = new ModalMarkus('#about_dialog');
  window.dialog_modal.modal_dialog.dialog( "option", "height", 670 );
  window.dialog_modal.modal_dialog.dialog( "option", "width", 600 );
  window.redirect_modal = new ModalMarkus('#redirect_dialog');

});