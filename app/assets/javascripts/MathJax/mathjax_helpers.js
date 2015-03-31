// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
    MathJax.Hub.Queue(['Typeset', MathJax.Hub]);
}

function hideAnnotationPreview() {
    document.getElementById('annotation_preview').hide();
    document.getElementById('annotation_preview_title').hide();

    // recenter dialog
    var dialog = jQuery('#create_annotation_dialog');
    dialog.css('margin-left', -1 * dialog.width() / 2);
}

function showAnnotationPreview() {
    document.getElementById('annotation_preview').show();
    document.getElementById('annotation_preview_title').show();

    // recenter dialog
    var dialog = jQuery('#create_annotation_dialog');
    dialog.css('margin-left', -1 * dialog.width() / 2);
}

function setPreviewMaxWidth() {
    jQuery('#annotation_preview')
        .css('max-width', jQuery('#annotation_preview_title').width());
}

function updateAnnotationPreview() {
    var newAnnotation = document.getElementById('new_annotation_content').value;

    var preview = document.getElementById('annotation_preview');
    preview.innerHTML = newAnnotation;

    setPreviewMaxWidth();
    showAnnotationPreview();

    // typeset the preview
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, preview]);
}