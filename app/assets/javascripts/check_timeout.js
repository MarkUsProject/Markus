(function () {
  let intervalId;
  let sessionExpired = false;

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
    fetch(Routes.check_timeout_main_index_path())
      .then(response => {
        if (response.status === 401) {
          sessionExpired = true;
          stopPolling();
          return;
        }

        return response.text();
      })
      .then(script => {
        if (script) {
          eval(script);
        }
      });
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  document.addEventListener("visibilitychange", () => {
    if (document.hidden) {
      stopPolling();
    } else {
      checkTimeout();
      if (!sessionExpired) {
        startPolling();
      }
    }
  });
})();
