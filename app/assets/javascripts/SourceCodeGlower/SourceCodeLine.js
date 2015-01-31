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
SourceCodeLine.prototype.glow = function(annotation_id, start_column, end_column) {
  // Increase the depth and turn on design mode for highlighting
  this.incGlowDepth(1);

  // Set the selection for the highlight command, save so we can unselect after
  this.glowRangeSpans(annotation_id, this.getLineNode(), start_column,
    (end_column == -1) ? this.getLineNode().textContent.length : end_column);
}

// Creates a fake mouse selection of text range within node param
SourceCodeLine.prototype.glowRangeSpans = function(annotation_id, node, start, end) {
  var textNodes = this.getAllTextNodes(node); // All text nodes contained in node
  var annotation_nodes = new Array();

  // Iterate over text nodes, add length of passed nodes, save start and break at end
  var start_node = null;
  var start_node_offset = 0;
  var end_node = null;
  var end_node_offset = 0;

  var foundStart = false;
  var currentCharCount = 0; // The amount of characters we've passed
  for (var i = 0; i < textNodes.length; i++) {
    var endCharCount = currentCharCount + textNodes[i].length;
    // If the start is between the current count and the end of the current node, save it
    if (!foundStart && start >= currentCharCount && start <= endCharCount) {
      foundStart = true;

      // Split the node if the glow starts inside of it
      if (start != endCharCount) {
        // Save reference to span node
        if ( textNodes[i].parentNode.parentNode == node){
          start_node = document.createElement("span");
          start_node.innerHTML = textNodes[i].textContent;
          textNodes[i].parentNode.insertBefore(start_node, textNodes[i].nextSibling);
          textNodes[i].parentNode.removeChild(textNodes[i]);
          textNodes[i] = start_node.childNodes[0];
        }
        else {
          start_node = textNodes[i].parentNode;
        }
        start_node_offset = start - currentCharCount;
      }
    }
    // Adds a class to the nodes between the start and stop
    else if (foundStart && end >= endCharCount){
      textNodes[i].parentNode.setAttribute(
        "data-annotationID" + annotation_id.toString(), annotation_id.toString());

      var glow_depth = textNodes[i].parentNode.getAttribute("data-annotationDepth");
      textNodes[i].parentNode.setAttribute("data-annotationDepth",
        glow_depth == null ? "1" : (parseInt(glow_depth) + 1).toString());

      textNodes[i].parentNode.addClass('source_code_glowing_' +
        (glow_depth == null ? "1" : (parseInt(glow_depth) + 1)));
    }

    // If foundStart and the current node contains the end, save it (can be the same as start_node)
    if (foundStart && end < endCharCount && currentCharCount != end) {
      // Save reference to span
      if ( textNodes[i].parentNode.parentNode == node){
        end_node = document.createElement("span");
        end_node.innerHTML = textNodes[i].textContent;
        textNodes[i].parentNode.insertBefore(end_node, textNodes[i].nextSibling);
        textNodes[i].parentNode.removeChild(textNodes[i]);
      }
      else {
        end_node = textNodes[i].parentNode;
      }
      end_node_offset = end - currentCharCount;
      break;
    }
    currentCharCount = endCharCount;
  }

  // Create and swap in new spans, first case if the start and end nodes match
  if (start_node != null && end_node != null && start_node == end_node){
    // Split the node into 3 spans
    var start_span_plain = document.createElement("span");
    var middle_span_glow = document.createElement("span");
    var end_node_plain = document.createElement("span");
    start_span_plain.innerHTML = start_node.textContent.substr(0, start_node_offset);
    middle_span_glow.innerHTML = start_node.textContent.substr(start_node_offset, end_node_offset - start_node_offset);
    end_node_plain.innerHTML = start_node.textContent.substr(end_node_offset);

    // Keep the source code classes
    if(start_node.classList.length > 0) {
      start_span_plain.classList.add(start_node.classList);
      middle_span_glow.classList.add(start_node.classList);
      end_node_plain.classList.add(start_node.classList);
    }
    middle_span_glow.setAttribute(
      "data-annotationID" + annotation_id.toString(), annotation_id.toString());

    var glow_depth = middle_span_glow.getAttribute("data-annotationDepth");
    middle_span_glow.setAttribute("data-annotationDepth",
      glow_depth == null ? "1" : (parseInt(glow_depth) + 1).toString());

    middle_span_glow.addClass('source_code_glowing_' +
    (glow_depth == null ? "1" : (parseInt(glow_depth) + 1)));

    // Insert the new spans, remove the old one
    start_node.parentNode.insertBefore(end_node_plain, start_node.nextSibling);
    start_node.parentNode.insertBefore(middle_span_glow, start_node.nextSibling);
    start_node.parentNode.insertBefore(start_span_plain, start_node.nextSibling);
    start_node.parentNode.removeChild(start_node);
  }
  else {
    if( start_node != null){
      var start_span_plain = start_node.clone(false);
      var start_span_glow = start_node.clone(false);
      start_span_plain.innerHTML = start_node.textContent.substr(0, start_node_offset);
      start_span_glow.innerHTML = start_node.textContent.substr(start_node_offset);

      start_span_glow.setAttribute(
        "data-annotationID" + annotation_id.toString(), annotation_id.toString());

      var glow_depth = start_span_glow.getAttribute("data-annotationDepth");
      start_span_glow.setAttribute("data-annotationDepth",
        glow_depth == null ? "1" : (parseInt(glow_depth) + 1).toString());

      start_span_glow.addClass('source_code_glowing_' +
      (glow_depth == null ? "1" : (parseInt(glow_depth) + 1)));

      start_node.parentNode.insertBefore(start_span_plain, start_node.nextSibling);
      start_span_plain.parentNode.insertBefore(start_span_glow, start_span_plain.nextSibling);
      start_node.parentNode.removeChild(start_node);
    }

    if (end_node != null){
      var end_span_plain = end_node.clone(false);
      var end_span_glow = end_node.clone(false);
      end_span_plain.innerHTML = end_node.textContent.substr(end_node_offset);
      end_span_glow.innerHTML = end_node.textContent.substr(0, end_node_offset);

      end_span_glow.setAttribute(
        "data-annotationID" + annotation_id.toString(), annotation_id.toString());

      var glow_depth = end_span_glow.getAttribute("data-annotationDepth");
      end_span_glow.setAttribute("data-annotationDepth",
        glow_depth == null ? "1" : (parseInt(glow_depth) + 1).toString());

      end_span_glow.addClass('source_code_glowing_' +
        (glow_depth == null ? "1" : (parseInt(glow_depth) + 1)));
      end_node.parentNode.insertBefore(end_span_glow, end_node.nextSibling);
      end_span_glow.parentNode.insertBefore(end_span_plain, end_span_glow.nextSibling);
      end_node.parentNode.removeChild(end_node);
    }
  }

  //// Add data attributes for use in unglow
  //for (var i = 0; i < annotation_nodes.length; i++){
  //  annotation_nodes[i].setAttribute(
  //    "data-annotationID" + annotation_id.toString(),
  //    annotation_id.toString());
  //
  //  var glow_depth = annotation_nodes[i].getAttribute("data-annotationDepth");
  //  annotation_nodes[i].setAttribute(
  //    "data-annotationDepth",
  //    glow_depth == null ? "1" : (parseInt(glow_depth) + 1).toString());
  //}
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


// Decrease a Source Code Line's glow depth
SourceCodeLine.prototype.unGlow = function(annotation_id) {
  // Is this line glowing?
  if (this.isGlowing()) {
    var textNodes = this.getAllTextNodes(this.getLineNode());

    // Create an array of glow nodes (spans)
    for (var i = 0; i < textNodes.length; i++){
      if (textNodes[i].parentNode.getAttribute(
          "data-annotationID" + annotation_id.toString()) == annotation_id.toString()){
        // Check and update the glow depth to handle nested annotations
        var glow_depth = textNodes[i].parentNode.getAttribute("data-annotationDepth");
        textNodes[i].parentNode.setAttribute(
          "data-annotationDepth",
          (parseInt(glow_depth) - 1).toString());

        textNodes[i].parentNode.removeClass("source_code_glowing_" + glow_depth);
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
