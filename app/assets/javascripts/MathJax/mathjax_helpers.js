// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function updatePreview(source, des) {
  var newAnnotation = document.getElementById(source);
  var preview = document.getElementById(des);

  if (preview !== null && newAnnotation !== null) {
    preview.innerHTML = marked(newAnnotation.value, {sanitize: true});
    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
  }
}

$(document).ready(function () {
  // Allow inline single dollar sign notation
  MathJax.Hub.Config({
    tex2jax: {inlineMath: [['$', '$'], ['\\(', '\\)']]},
    extensions: []
  });
  (function () {
    var EXT = MathJax.Extension, mm, mz;
    MathJax.Hub.Register.StartupHook("End Typeset",function () {
      mm = EXT.MathMenu; mz = EXT.MathZoom;
      EXT.MathMenu = EXT.MathZoom = {};
    });
    MathJax.Hub.Queue(function () {
      if (mm) {EXT.MathMenu = mm} else {delete EXT.MathMenu}
      if (mm) {EXT.MathZoom = mz} else {delete EXT.MathZoom}
    });
  })();
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
