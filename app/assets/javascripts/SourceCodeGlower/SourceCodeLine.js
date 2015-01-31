/** Source Code Line Class

    This class represents a single line of source code, and controls "glowing", and
    mouseover/mouseout observing.  It's an abstract class that needs to be implemented
    for the particular source code highlighting library being used

    Rules:
    - When a line is "glowing", it has a class of "source_code_glowing_" and then
      a number indicating the "depth" of its glow.  This allows for annotation overlapping.
      For example, 5 lines of source could be "glowed", and then three lines within that
      original 5 could be glowed again - their glow depth will increase.
    - This is an abstract class that needs to be implemented for the particular source
      code highlighting library being used
*/

function SourceCodeLine(line_node) {
  // line_node is the DOM element that holds a line of source code
  this.line_node         = line_node;
  this.glow_depth        = 0;
  this.observe_over_func = null;
  this.observe_out_func  = null;
  this.is_observing      = false;
}

// Increase a Source Code Line's glow depth
// The base of the new glow functionality was found here:
// http://stackoverflow.com/questions/6240139/highlight-text-range-using-javascript
SourceCodeLine.prototype.glow = function(start_column, end_column) {
  // Increase the depth and turn on design mode for highlighting
  this.incGlowDepth(1);
  document.designMode = "on";

  // Set the selection for the highlight command, save so we can unselect after
  var sel = this.selectGlowRange(this.getLineNode(),
    start_column,
    (end_column == -1) ? this.getLineNode().textContent.length : end_column);

  // If hilitecolor doesnt work try backcolor
  //if (!document.execCommand("HiliteColor", false, this.getGlowDepth() == 1 ? '#fffcc4' : '#ff9')) {
  //  document.execCommand("BackColor", false, this.getGlowDepth() == 1 ? '#fffcc4' : '#ff9');
  //}

  // Turn off design mode and remove fake mouse selection
  document.designMode = "off";
  sel.removeAllRanges();
}

// Creates a fake mouse selection of text range within node param
SourceCodeLine.prototype.selectGlowRange = function(node, start, end) {
  var range = document.createRange(node); // Used to track start/end nodes and their offsets
  var textNodes = this.getAllTextNodes(node); // All text nodes contained in node

  var foundStart = false;
  var currentCharCount = 0; // The amount of characters we've passed

  //init swaps outside of loop
  var start_span_plain = null;
  var start_span_glow = null;
  var end_span_plain = null;
  var end_span_glow = null;

  // Iterate over text nodes, add length of passed nodes, save start and break at end

  // TODO:
  // Case 1: highlight one entire node
  // Case 2: highlight a section of one node
  // Case 3: highlight two separate nodes + everything in between

  // IDEA: use for loop to find start and end nodes + save offset.
  // Then after loop check for the case and handle there ie (start_node == end_node)
  for (var i = 0; i < textNodes.length; i++) {
    var endCharCount = currentCharCount + textNodes[i].length;

    // If the start is between the current count and the end of the current node, save it
    if (!foundStart && start >= currentCharCount && (start < endCharCount || (start == endCharCount && i < textNodes.length))) {
      range.setStart(textNodes[i], start - currentCharCount); // Set start as offset in current text node
      foundStart = true;

      // Split the node if the glow starts inside of it
      if (start != endCharCount) {
        // Save reference to span
        var start_node = textNodes[i].parentNode;

        // Create two separate spans, one with the highlight the other without
        // Save and replace after loop to avoid changing indexes/offsets
        start_span_plain = document.createElement("span");
        start_span_glow = document.createElement("span");
        start_span_plain.innerHTML = start_node.textContent.substr(0, start - currentCharCount);
        start_span_glow.innerHTML = start_node.textContent.substr(start - currentCharCount);
        if(start_node.classList.length > 0) {
          start_span_plain.classList.add(start_node.classList);
          start_span_glow.classList.add(start_node.classList);
        }
        start_span_glow.addClass('source_code_glowing_' + this.getGlowDepth());


        // TODO check if end is in the same node and handle that special case, then break! BRAH
      }
    }
    // Adds a class to the nodes between the start and stop
    else if (foundStart && end >= endCharCount){
      textNodes[i].parentNode.addClass('source_code_glowing_' + this.getGlowDepth());
    }
    // If we have the start and the current node contains the end, save it
    else if (foundStart && end < endCharCount) {
      //range.setEnd(textNodes[i], end - currentCharCount);

      // Save reference to span
      var end_node = textNodes[i].parentNode;

      // Create two separate spans, one with the highlight the other without
      // Save and replace after loop to avoid changing indexes/offsets
      var end_span_plain = document.createElement("span");
      var end_span_glow = document.createElement("span");
      end_span_plain.innerHTML = end_node.textContent.substr(end - currentCharCount);
      end_span_glow.innerHTML = end_node.textContent.substr(0, end - currentCharCount);
      if ( end_node.classList.length > 0) {
        end_span_plain.classList.add(end_node.classList);
        end_span_glow.classList.add(end_node.classList);
      }
      end_span_glow.addClass('source_code_glowing_' + this.getGlowDepth());
      break;
    }

    currentCharCount = endCharCount;
  }

  // Insert the start nodes and remove the old one
  if( start_span_glow != null && start_span_plain != null)
  {
    start_node.parentNode.insertBefore(start_span_plain, start_node.nextSibling);
    start_span_plain.parentNode.insertBefore(start_span_glow, start_span_plain.nextSibling);
    start_node.parentNode.removeChild(start_node);
  }

  // Insert the end nodes and remove the old one
  if( end_span_glow != null && end_span_plain != null)
  {
    end_node.parentNode.insertBefore(end_span_glow, end_node.nextSibling);
    end_span_glow.parentNode.insertBefore(end_span_plain, end_span_glow.nextSibling);
    end_node.parentNode.removeChild(end_node);
  }

  // Grab the window selection, clear old range, and set custom range
  var sel = window.getSelection();
  sel.removeAllRanges();
  sel.addRange(range);

  return sel;
}

// Recursive method returns an array of all text nodes contained in node param
SourceCodeLine.prototype.getAllTextNodes = function(node) {
  var textNodes = [];
  if (node.nodeType === 3) { // Push if text node
    textNodes.push(node);
  }
  else if(node.nodeType === 1){ // Recursively return all contained text nodes
    for (var i = 0; i < node.childNodes.length; i++) {
      textNodes.push.apply(textNodes, this.getAllTextNodes(node.childNodes[i]));
    }
  }
  return textNodes;
}

// Get the actual elements so we can
SourceCodeLine.prototype.getAllSpanElements = function(node){
  var textNodes = [];
  if (node.nodeName === "SPAN") { // Push if text node
    textNodes.push(node);
  }

  // Recursively return all contained text nodes
  for (var i = 0; i < node.children.length; i++) {
    textNodes.push.apply(textNodes, this.getAllSpanElements(node.children[i]));
  }

  return textNodes;
}

// Decrease a Source Code Line's glow depth
SourceCodeLine.prototype.unGlow = function() {
  // Is this line glowing?
  if (this.isGlowing()) {
    var textElements = this.getAllSpanElements(this.getLineNode());

    // Create an array of glow nodes (spans)
    for (var i = 0; i < textElements.length; i++){
      if (textElements[i].style.backgroundColor != ""){
        textElements[i].removeAttribute("style");
      }
    }
  }

  // Decrease the glow depth
  this.decGlowDepth(1);
}

SourceCodeLine.prototype.incGlowDepth = function(amount) {
  this.setGlowDepth(this.getGlowDepth() + amount);
}

SourceCodeLine.prototype.decGlowDepth = function(amount) {
  this.setGlowDepth(Math.max(this.getGlowDepth() - amount, 0));
}

SourceCodeLine.prototype.getLineNode = function() {
  return this.line_node;
}

SourceCodeLine.prototype.getGlowDepth = function() {
  return this.glow_depth;
}

SourceCodeLine.prototype.setGlowDepth = function(glow_depth) {
  this.glow_depth = glow_depth;
}

SourceCodeLine.prototype.isGlowing = function() {
  return this.getGlowDepth() > 0;
}

// Handle all observations, and store references in the functions so that
// we can remove observations easily
SourceCodeLine.prototype.observe = function(over_func, out_func) {
  // If we're already observing, we don't need to do this.
  if (this.isObserving()) { return; }

  this.setObserveOverFunc(over_func);
  this.setObserveOutFunc(out_func);
  this.getLineNode().onmouseover = this.getObserveOverFunc();
  this.getLineNode().onmouseout  = this.getObserveOutFunc();
  this.setObserving(true);
}

SourceCodeLine.prototype.stopObserving = function() {
  // If we're not observing this, this isn't a problem
  if (!this.isObserving()) { return; }

  this.getLineNode().onmouseover = null;
  this.getLineNode().onmouseout  = null;
  this.setObserving(false);
}

SourceCodeLine.prototype.setObserveOverFunc = function(func) {
  this.observe_over_func = func;
}

SourceCodeLine.prototype.getObserveOverFunc = function() {
  return this.observe_over_func;
}

SourceCodeLine.prototype.setObserveOutFunc = function(func) {
  this.observe_out_func = func;
}

SourceCodeLine.prototype.getObserveOutFunc = function(func) {
  return this.observe_out_func;
}

SourceCodeLine.prototype.isObserving = function() {
  return this.is_observing;
}

SourceCodeLine.prototype.setObserving = function(is_observing) {
  this.is_observing = is_observing;
}
