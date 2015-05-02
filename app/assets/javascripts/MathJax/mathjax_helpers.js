// Function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function recenterDialog() {
  var dialog = jQuery('#create_annotation_dialog');
  dialog.css('margin-left', -1 * dialog.width() / 2);
}

function hideAnnotationPreview() {
  document.getElementById('annotation-preview').style.display = 'none';
  recenterDialog();
}

function showAnnotationPreview() {
  document.getElementById('annotation-preview').style.display = '';
  recenterDialog();
}

function updateAnnotationPreview() {
  var newAnnotation = document.getElementById('new_annotation_content').value;

  var preview = document.getElementById('annotation-preview-text');
  preview.innerHTML = newAnnotation;

  showAnnotationPreview();

  // Typeset the preview
  MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
}
