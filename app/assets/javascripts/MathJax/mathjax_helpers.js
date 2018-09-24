// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function updatePreview(source, destination) {
  var newAnnotation = document.getElementById(source);
  var preview = document.getElementById(destination);

  if (preview !== null && newAnnotation !== null) {
    preview.innerHTML = marked(newAnnotation.value, {sanitize: true});
    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, destination]);
  }
}

$(document).ready(function () {
  // Update when the document loads so preview is available for existing comments/annotations
  updatePreview('new_annotation_content', 'annotation_preview');
  updatePreview('overall_comment_text_area', 'overall_comment_preview');
  updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');

  $(document).on("keyup", "#new_annotation_content", function () {
    updatePreview('new_annotation_content', 'annotation_preview');
  });
  $(document).on("keyup", "#overall_comment_text_area", function () {
    updatePreview('overall_comment_text_area', 'overall_comment_preview');
  });
  $(document).on("keyup", "#overall_remark_comment_text_area", function () {
    updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');
  });
});
