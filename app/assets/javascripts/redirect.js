$(document).ready(() => {
  $(document).ajaxError((event, xhr) => {
    if (xhr.status === 403) {
      session_expired_modal.open()
    }
  });
});
