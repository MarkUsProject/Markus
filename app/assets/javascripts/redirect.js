function redirectToLogin() {
  window.location = Routes.root_url();
}

$(document).ajaxError((event, xhr) => {
  if (xhr.status === 403) {
    redirect_modal.open();
  }
});
