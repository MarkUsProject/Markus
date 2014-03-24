//= require prototype
//= require jquery
//= require jquery-ui
//= require jquery_ujs


//var helpButton = document.getElementsByClassName('.help');
jQuery(document).ready(function() {
jQuery(".help").click(function(){
    jQuery(".help-message").toggle();
});
});
