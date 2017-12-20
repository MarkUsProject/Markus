$(document).ready(() => {
  let redirect_modal = new ModalMarkus('#redirect_dialog');
  $(document).ajaxError((event, xhr) => {
    if (xhr.status === 403) {
      redirect_modal.open();
    }
  });

  let $redirect_dialog = $('#redirect_dialog');

  $redirect_dialog.find('button.cancel').click(() => {
    redirect_modal.close();
  });

  $redirect_dialog.find('button.submit').click(() => {
    window.location = Routes.root_url();
  });
});
