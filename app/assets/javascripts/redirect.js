$(document).ready(() => {
  $(document).ajaxError((event, xhr) => {
    if (xhr.status === 403) {
      window.location.reload()
    }
  });
});
