// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function hideAnnotationPreview() {
    jQuery('#annotation_preview').hide();
    jQuery('#annotation_preview_title').hide();

    // recenter dialog
    var dialog = jQuery('#create_annotation_dialog');
    dialog.css('margin-left', -1 * dialog.width() / 2);
}

function showAnnotationPreview() {
    jQuery('#annotation_preview').show();
    jQuery('#annotation_preview_title').show();

    // recenter dialog
    var dialog = jQuery('#create_annotation_dialog');
    dialog.css('margin-left', -1 * dialog.width() / 2);
}

function updateAnnotationPreview() {
    var newAnnotation = document.getElementById('new_annotation_content').value;

    var preview = document.getElementById('annotation_preview');
    preview.innerHTML = marked(newAnnotation);

    showAnnotationPreview();

    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
}
