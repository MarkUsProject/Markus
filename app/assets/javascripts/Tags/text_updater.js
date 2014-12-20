jQuery(document).ready(function() {
  var MAX_SIZE = 120;
  var current_char = 0;

  // Gets the area where the char count is.
  var char_count = jQuery('#descript_amount');
  char_count.html(current_char + '/' + MAX_SIZE);

  //Sets the max size on the text field.
  jQuery('#description').attr('maxlength', MAX_SIZE.toString());

  // Now, on key up, we update.
  jQuery('#description').keyup(function() {
    current_char = jQuery('#description').val().length;
    char_count.html(current_char + '/' + MAX_SIZE);
  });
});
