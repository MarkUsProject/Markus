(function () {
  const domContentLoadedCB = () => {
    $(document).ajaxError((event, xhr) => {
      if (xhr.status === 403) {
        session_expired_modal.open();
        $("#session-expired-modal-close").click(function () {
          session_expired_modal.close();
          window.location.reload();
        });
      }
    });
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
})();
