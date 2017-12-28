$(document).ready(() => {
  $('.help-message-box').hide();
  $('.help-message-title').hide();
  $('.help-break').hide();

  $('.help, .title-help').click((event) => {
    const help_section = $(event.currentTarget).attr('class').split(' ')[1];
    $('.help-message-box').filter('.' + help_section).toggle();
    $('.help-message-title').filter('.' + help_section).toggle();
    $('.help-break').filter('.' + help_section).toggle();
  });
});
