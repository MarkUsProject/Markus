jQuery(document).ready(function() {
  jQuery('.help-message-box').hide();
  jQuery('.help-message-title').hide();
  jQuery('.help-break').hide();

  jQuery('#section').on('click','.help, .title-help',function(){
    var help_section = jQuery(this).attr('class').split(' ')[1];
    jQuery('.help-message-box').filter('.' + help_section).toggle();
    jQuery('.help-message-title').filter('.' + help_section).toggle();
    jQuery('.help-break').filter('.' + help_section).toggle();
  });
});
