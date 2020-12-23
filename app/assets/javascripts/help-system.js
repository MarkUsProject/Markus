$(document).ready(() => {
  $('.help, .title-help, .inline-help').click(event => {
    $(event.currentTarget).children().toggle();
  });
});
