(function () {
  let intervalId;
  const domContentLoadedCB = () => {
    startPolling();
  };

  const startPolling = () => {
    if (intervalId) return;

    intervalId = setInterval(() => {
      checkTimeout();
    }, 120000);
  };

  const stopPolling = () => {
    clearInterval(intervalId);
    intervalId = null;
  };

  const checkTimeout = () => {
    $.get(Routes.check_timeout_main_index_path());
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      stopPolling();
    } else {
      checkTimeout();
      startPolling();
    }
  });
})();
