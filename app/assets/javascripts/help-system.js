document.addEventListener("DOMContentLoaded", () => {
  $(".help, .title-help, .inline-help").click(event => {
    $(event.currentTarget).children().toggle();
  });
});
