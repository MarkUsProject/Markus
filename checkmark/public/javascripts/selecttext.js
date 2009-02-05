function getSelectedLines(target_text) {
  target_text = $(target_text);
  var anchor = null;
  var focus = null;
  if(window.getSelection) {
    anchor = window.getSelection().anchorNode;
    focus = window.getSelection().focusNode;
  }
  else if(document.selection) {
    //TODO:  Fix for IE
    /*
    var range = document.selection.createRange();
        var stored_range = range.duplicate();
        var element = $(target_text);
        stored_range.moveToElementText( element );
        stored_range.setEndPoint( 'EndToEnd', range );
        start = stored_range.text.length - range.text.length;
        end = start + range.text.length;
        var codeRange = document.body.createTextRange();
        codeRange.moveToElementText(element);
        if (!codeRange.inRange(stored_range)){
            return false;
        }
     */
    alert('Not yet implemented for Internet Explorer');
  }
  else {
    //TODO:  Catch other browsers?
    alert('Not yet implemented for this browser');
  }
  
  subject_array = $$('.dp-j')[0];
  if(subject_array == null) {
    alert('Could not find the code viewer');
  }
    
  var anchor_node_line = findCodeLineInArray(anchor, subject_array) + 1;
  var focus_node_line = findCodeLineInArray(focus, subject_array) + 1;
  
  
  if(anchor_node_line > focus_node_line) {
    var swap_var = focus_node_line;
    focus_node_line = anchor_node_line;
    anchor_node_line = swap_var;
  }
  
  return {line_start: anchor_node_line, line_end: focus_node_line};
  
}

function findCodeLineInArray(node, target_array) {
  if(node == null || node.parentNode == null) {
    return null;
  }
  var line_num = -1;
  var descendents_list = $(target_array).immediateDescendants();
  var code_line_node = getCodeLineNode(node.parentNode);
  line_num = descendents_list.indexOf(code_line_node);
  return line_num;
}

function getCodeLineNode(node) {
  var current_node = $(node);
  var code_line_node = null;
  current_node.ancestors().each(function(a_node) {
    if(a_node.tagName == 'LI') {
      code_line_node = a_node;
      $break;
    }
  });
  return code_line_node;

}

function highlightLine(lineNum) {
    console.log('Attempting to highlight line ' + lineNum);
    var code = $$('.dp-j')[0];
    //Make sure we found the OL tag containing the code
    if(code == null) return false;
    var target_line  = code.immediateDescendants()[lineNum - 1];
    if(target_line == null) {
      console.log('Failed to highlight line ' + lineNum);
      return;
    }
      
    if($(target_line).hasClassName('annotation_highlighted_text')) {
      $(target_line).removeClassName('annotation_highlighted_text');
      $(target_line).addClassName('annotation_highlighted_text_overlap');
    }
    else {
      $(target_line).removeClassName('alt')
      $(target_line).addClassName('annotation_highlighted_text')
    }
    return target_line;
}

function highlightRange(range) {
    range.each(function(line_num) {
        range_array.push(highlightLine(i));
    });
}
