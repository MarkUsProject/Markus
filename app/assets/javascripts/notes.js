/** Page-specific event handlers for notes/new.html.erb */

document.addEventListener("DOMContentLoaded", function () {
  $("#noteable_type select").change(function () {
    document.getElementById("working").style.display = "";

    var params = {
      noteable_type: this.value,
      authenticity_token: AUTH_TOKEN,
    };

    $.ajax({
      url: "noteable_object_selector",
      data: params,
      type: "POST",
    }).done(() => {
      document.getElementById("working").style.display = "none";
    });
  });
});
