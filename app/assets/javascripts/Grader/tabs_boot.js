(function () {
  const domContentLoadedCB = function () {
    $("#code_pane").tabs();
    $("#mark_pane").tabs();
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
