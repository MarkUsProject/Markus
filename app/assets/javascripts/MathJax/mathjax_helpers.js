// function that reloads the DOM for
// MathJax (http://www.mathjax.org/docs/1.1/typeset.html)
function reloadDOM() {
    MathJax.Hub.Queue(["Typeset", MathJax.Hub]);
}

var timeout;
function updateAnnotationPreview(){
    var updatedAnnotation = document.getElementById("new_annotation_content").value;

    var previewParagraph = document.getElementById("annotation_preview");
    var title = document.getElementById("annotation_preview_title");

    var firstIndex = updatedAnnotation.indexOf("$$");
    var secondIndex = updatedAnnotation.indexOf("$$", firstIndex + 1);

    if(firstIndex != -1 && secondIndex != -1 && firstIndex != secondIndex){
        title.show();
        previewParagraph.show();
        previewParagraph.innerHTML = updatedAnnotation;

        if(timeout){
            clearTimeout(timeout)
            timeout = null
        }

        // typeset the preview
        timeout = setTimeout(function() {
            MathJax.Hub.Queue(["Typeset", MathJax.Hub, previewParagraph]);
            clearTimeout(timeout)
        }, 3000);

    }else{
        title.hide();
        previewParagraph.hide()
    }
}