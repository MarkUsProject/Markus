// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function hideAnnotationPreview() {
    $('#annotation_preview').hide();
    $('#annotation_preview_title').hide();

    // recenter dialog
    var dialog = $('#annotation_dialog');
    dialog.css('margin-left', -1 * dialog.width() / 2);
}

function updateAnnotationPreview() {
    var newAnnotation = document.getElementById('new_annotation_content').value;

    var preview = document.getElementById('annotation_preview');
    preview.innerHTML = marked(newAnnotation);

    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
}

// Allow inline single dollar sign notation
MathJax.Hub.Config({
  tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}
});

var delay = (function(){
  var timer = 0;
  return function(callback, ms){
    clearTimeout (timer);
    timer = setTimeout(callback, ms);
  };
})();

$(document).on("keyup", "#new_annotation_content", function () {
  delay(function(){
    updateAnnotationPreview();
  }, 300 );
});
