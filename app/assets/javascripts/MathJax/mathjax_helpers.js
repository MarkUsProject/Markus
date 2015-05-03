// Function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function updateAnnotationPreview() {
  var newAnnotation = document.getElementById('new_annotation_content').value;

  var preview = document.getElementById('annotation-preview-text');
  preview.innerHTML = newAnnotation;

  // Typeset the preview
  MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);

  // Recenter dialog
  var dialog = jQuery('#create_annotation_dialog');
  dialog.css('margin-left', -1 * dialog.width() / 2);
}
