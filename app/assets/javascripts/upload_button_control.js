// Get the currently executing script ID for reference.
var page_scripts = document.getElementsByTagName("script");
var script_id = page_scripts[page_scripts.length - 1].id;

// Next, gets the upload id and user id.
var upload_id = _get("upload_id");
var button_id = _get("button_id");

var Function_List = {
  onDOMContentLoaded: function (u_id, b_id) {
    // Ensures only one upload field was entered.
    if ($(u_id).length != 1) return;

    // Checks to see if the file upload id changed.
    $("body").on("change", "#" + u_id, function () {
      if (document.getElementById(b_id[0]) === null) return;

      var filePath = this.value;
      var i;

      // Enables/Disables all buttons.
      for (i = 0; i < $(b_id).length; i++) {
        // Either disables or enables upload buttons.
        if (filePath === "") {
          document.getElementById(b_id[i]).disabled = true;
        } else {
          document.getElementById(b_id[i]).disabled = false;
        }
      }
    });
  },
};

if (document.readyState === "loading") {
  document.addEventListener(
    "DOMContentLoaded",
    Function_List.onDOMContentLoaded(upload_id, button_id)
  );
} else {
  Function_List.onDOMContentLoaded(upload_id, button_id)();
}

function _get(param_name) {
  // Gets the correct attribute from the script.
  var scriptElement = document.getElementById(script_id);

  // Now creates an array with each element.
  return scriptElement.getAttribute(param_name).split(" ");
}
