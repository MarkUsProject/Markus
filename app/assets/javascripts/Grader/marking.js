(function () {
  const domContentLoadedCB = function () {
    // Handle indenting in the new annotation textarea (2 spaces)
    $("#new_annotation_content").keydown(function (e) {
      var keyCode = e.keyCode || e.which;

      if (keyCode == 9) {
        e.preventDefault();
        var start = this.selectionStart;
        var end = this.selectionEnd;

        // Add the 2 spaces
        this.value = this.value.substring(0, start) + "  " + this.value.substring(end);

        // Put caret in correct position
        this.selectionStart = this.selectionEnd = start + 2;
      }
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();
