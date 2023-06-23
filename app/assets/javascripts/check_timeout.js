(function () {
  const domContentLoadedCB = () => {
    setInterval(() => {
      $.get(Routes.check_timeout_main_index_path());
    }, 120000);
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
})();
