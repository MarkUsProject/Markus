document.addEventListener("DOMContentLoaded", () => {
  $(document).ajaxError((event, xhr) => {
    if (xhr.status === 403) {
      session_expired_modal.open();
      $("#session-expired-modal-close").click(function () {
        session_expired_modal.close();
        window.location.reload();
      });
    }
  });
});
