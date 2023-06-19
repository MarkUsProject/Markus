$(document).ready(() => {
  $(".help, .title-help, .inline-help")
    .click(event => {
      $(event.currentTarget).children("p").toggle();
    })
    .prepend(HELP_ICON_HTML);
});
