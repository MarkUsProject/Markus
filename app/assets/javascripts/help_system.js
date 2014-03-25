//= require prototype
//= require jquery
//= require jquery-ui
//= require jquery_ujs

jQuery(document).ready(function() {
    jQuery(".help-message").hide();
    jQuery(".help").click(function(){
        var help_section = (jQuery(this).attr('class').split(' ')[1]);
        jQuery(".help-message").filter("."+help_section).toggle();
    });
});
