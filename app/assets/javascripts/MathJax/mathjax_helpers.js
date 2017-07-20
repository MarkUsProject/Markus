// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
  MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function updatePreview(source, des) {
  delay(function () {
    var newAnnotation = document.getElementById(source);

    var preview = document.getElementById(des);

    if(preview != null && newAnnotation != null){
      preview.innerHTML = marked(newAnnotation.value);
      // typeset the preview
      MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
    }
  }, 300);
}

// Allow inline single dollar sign notation
MathJax.Hub.Config({
  tex2jax: {inlineMath: [['$', '$'], ['\\(', '\\)']]}
});

var delay = (function () {
  var timer = 0;
  return function (callback, ms) {
    clearTimeout(timer);
    timer = setTimeout(callback, ms);
  };
})();

$(document).on("keyup", "#new_annotation_content", function () {
  updatePreview('new_annotation_content', 'annotation_preview');
});
$(document).on("keyup", "#overall_comment_text_area", function () {
  updatePreview('overall_comment_text_area', 'overall_comment_preview');
});
$(document).on("keyup", "#overall_remark_comment_text_area", function () {
  updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');
});

// Update when the document loads so preview is available for existing comments/annotations
updatePreview('new_annotation_content', 'annotation_preview');
updatePreview('overall_comment_text_area', 'overall_comment_preview');
updatePreview('overall_remark_comment_text_area', 'overall_remark_comment_preview');


