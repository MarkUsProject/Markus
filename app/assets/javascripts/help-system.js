(function () {
  const domContentLoadedCB = () => {
    $(".help, .title-help, .inline-help").click(event => {
      $(event.currentTarget).children().toggle();
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
