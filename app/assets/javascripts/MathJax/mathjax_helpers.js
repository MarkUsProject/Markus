// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  Array.prototype.forEach.call(
    document.getElementsByClassName("annotation_text_display"),
    element => {
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, element]);
    }
  );
}

function updatePreview(source, destination) {
  var newAnnotation = document.getElementById(source);
  var preview = document.getElementById(destination);

  if (preview !== null && newAnnotation !== null) {
    preview.innerHTML = safe_marked(newAnnotation.value);
    // typeset the preview
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, destination]);
  }
}

document.addEventListener("DOMContentLoaded", function () {
  $(document).on("keyup", "#new_annotation_content", function () {
    updatePreview("new_annotation_content", "annotation_preview");
  });
});
