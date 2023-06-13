document.addEventListener("DOMContentLoaded", function () {
  var MAX_SIZE = 120;
  var current_char = 0;

  // Gets the area where the char count is.
  var char_count = $("#descript_amount");
  char_count.html(current_char + "/" + MAX_SIZE);

  //Sets the max size on the text field.
  $("#description").attr("maxlength", MAX_SIZE.toString());

  // Now, on key up, we update.
  $("#description").keyup(function () {
    current_char = $("#description").val().length;
    char_count.html(current_char + "/" + MAX_SIZE);
  });
});
