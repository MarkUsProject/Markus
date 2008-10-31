function getSel() {

    if (window.getSelection) {
        var range = window.getSelection();
        if(!range.anchorNode) return null;
        
        var startNode = range.anchorNode;
        var endNode = range.focusNode;

        // TODO make sure that the text that is selected if from the textArea

        //these start and end points are relevant to the start and end node
        var startOffset = range.anchorOffset;
        var endOffset = range.focusOffset;
        
        pre = document.getElementById('codetext');
        preContent = pre.innerHTML;

        var start = getStartPos(startNode, startOffset);
        var end = getEndPos(endNode, endOffset);

        // make sure that the start occurs before the end
        if (start > end) {
            var temp = end;
            end = start;
            start = temp;
        }

        if (start-end == 0)
            return false;
    }
    else if (document.selection) {
        // fill this in for IE
        var range = document.selection.createRange();
        var stored_range = range.duplicate();
        var element = $("contents");
        stored_range.moveToElementText( element );
        stored_range.setEndPoint( 'EndToEnd', range );
        start = stored_range.text.length - range.text.length;
        end = start + range.text.length;
        var codeRange = document.body.createTextRange();
        codeRange.moveToElementText(element);
        if (!codeRange.inRange(stored_range)){
            return false;
        }
    }
    else {
        alert("FIXME: Browser compatibility issue in highlight.js");
        return false;
    }


    var line_start = preContent.substring(0,start).split("\n").length;
    var line_end = preContent.substring(0,end).split("\n").length;


    alert("start: " + start + "\nend: " +  end + "\nline start: " + line_start + "\nline end:" + line_end);

    return {'pos_start': start, 
            'pos_end': end,
            'line_start': line_start,
            'line_end': line_end};
}

/* Given a node and offset, get the final offset including the node's 
immediate children */
function getPosition(startNode, offset) {
    var curNode = startNode;
    var absOffset = offset;
    var prevSibling;

    // Embedded comment, want the parent node
    while ('codeviewer' != curNode.parentNode.parentNode.parentNode.id) {
        curNode = curNode.parentNode;
    }
    
    while (prevSibling = curNode.previousSibling) {
        var textLength = prevSibling.textContent.length;
        absOffset += textLength;
        curNode = prevSibling;
    }
    return absOffset;
}

/* Wrapper for getPosition (to make things more readable) */
function getStartPos(startNode, startOffset) {
    return getPosition(startNode, startOffset);
}

/* Wrapper for getPosition (to make things more readable) */
function getEndPos(endNode, endOffset) {
    return getPosition(endNode, endOffset);
}
