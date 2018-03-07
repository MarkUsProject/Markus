$(document).ready(() => {
  let redirect_modal = new ModalMarkus('#redirect_dialog');
  $(document).ajaxError((event, xhr) => {
    if (xhr.status === 403) {
      redirect_modal.open();
    }
  });

  $('#redirect_dialog').find('button.submit').click(() => {
    window.location = Routes.root_url();
  });
});
