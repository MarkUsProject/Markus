(function () {
  const domContentLoadedCB = () => {
    setInterval(() => {
      $.get(Routes.check_timeout_main_index_path());
    }, 120000);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
