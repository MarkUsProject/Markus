$(document).ready(function() {
  $('.help-message-box').hide();
  $('.help-message-title').hide();
  $('.help-break').hide();

  $('.help, .title-help').click(function() {
    var help_section = $(this).attr('class').split(' ')[1];
    $('.help-message-box').filter('.' + help_section).toggle();
    $('.help-message-title').filter('.' + help_section).toggle();
    $('.help-break').filter('.' + help_section).toggle();
  });
});
