// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function updatePreview(source, des) {
  var newAnnotation = document.getElementById(source);
  var preview = document.getElementById(des);

  if (preview !== null && newAnnotation !== null) {
    preview.innerHTML = marked(newAnnotation.value);
    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
  }
}

$(document).ready(function () {
  // Allow inline single dollar sign notation
  MathJax.Hub.Config({
    tex2jax: {inlineMath: [['$', '$'], ['\\(', '\\)']]}
  });
  // Update when the document loads so preview is available for existing comments/annotations
  updatePreview('new_annotation_content', 'annotation_preview');
  updatePreview('overall_comment_text_area', 'overall_comment_preview');
  updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');
});

$(document).on("keyup", "#new_annotation_content", function () {
  updatePreview('new_annotation_content', 'annotation_preview');
});
$(document).on("keyup", "#overall_comment_text_area", function () {
  updatePreview('overall_comment_text_area', 'overall_comment_preview');
});
$(document).on("keyup", "#overall_remark_comment_text_area", function () {
  updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');
});
