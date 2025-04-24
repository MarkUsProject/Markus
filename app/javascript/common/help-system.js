(function () {
  const domContentLoadedCB = () => {
    $(".help, .title-help, .inline-help")
      .click(event => {
        $(event.currentTarget).children("p").toggle();
      })
      .prepend(HELP_ICON_HTML);
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
