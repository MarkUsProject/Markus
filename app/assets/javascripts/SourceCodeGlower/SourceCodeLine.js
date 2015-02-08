/** Source Code Line Class

    This class represents a single line of source code, and controls "glowing", and
    mouseover/mouseout observing.  It's an abstract class that needs to be implemented
    for the particular source code highlighting library being used

    Rules:
    - When a span is "glowing", it has a class of "source_code_glowing_" and then
      a number indicating the "depth" of its glow.  This allows for annotation overlapping.
      For example, 5 lines of source could be "glowed", and then three lines within that
      original 5 could be glowed again - their glow depth will increase.
    - Each span will have data attributes added to allow for depth tracking and
      to enable unglowing with overlapping annotations
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

// Increase a Source Code Line's glow depth, add listeners
// Splits nodes at start and end offsets if needed
SourceCodeLine.prototype.glow = function(annotation_id, start, end,
  hover_on_function, hover_off_function) {
  // Increase the depth and turn on design mode for highlighting
  this.incGlowDepth(1);

  // Save line node and get all text nodes in the line
  var node = this.getLineNode();
  var textNodes = this.getAllTextNodes(node);

  // Loop prep, for tracking nodes and character counts
  var start_node = null;
  var start_node_offset = 0;
  var end_node = null;
  var end_node_offset = 0;
  var foundStart = false;
  var currentCharCount = 0;

  // Loop over nodes, add length of passed nodes, save start and end then break
  for (var i = 0; i < textNodes.length; i++) {
    // End char offset of the current text node
    var endCharCount = currentCharCount + textNodes[i].length;

    // If start is between current count and end of the current node, save it
    if (!foundStart && start >= currentCharCount && start <= endCharCount) {
      foundStart = true;

      // Will need to split the node if the glow starts inside of it
      if (start != endCharCount) {
        // Save reference to span node, create span wrapper if blank space
        if (textNodes[i].parentNode.parentNode === node) {
          start_node = document.createElement("span");
          start_node.innerHTML = textNodes[i].textContent;
          textNodes[i].parentNode.replaceChild(start_node, textNodes[i]);
          textNodes[i] = start_node.childNodes[0];
        }
        else {
          start_node = textNodes[i].parentNode;
        }
        start_node_offset = start - currentCharCount;
      }
    }
    // Adds class/data/events to the nodes between the start and end
    else if (foundStart && end >= endCharCount) {
      var glow_depth = textNodes[i].parentNode.getAttribute("data-annotationDepth");
      textNodes[i].parentNode.setAttribute("data-annotationDepth",
        glow_depth == null ? "1" : (parseInt(glow_depth, 10) + 1).toString());
      textNodes[i].parentNode.setAttribute("data-annotationID" +
        annotation_id.toString(), annotation_id.toString());

      textNodes[i].parentNode.addClass('source_code_glowing_' +
        (glow_depth == null ? "1" : (parseInt(glow_depth, 10) + 1)));

      textNodes[i].parentNode.addEventListener("mouseover", hover_on_function);
      textNodes[i].parentNode.addEventListener("mouseout", hover_off_function);
    }

    // If foundStart & current node contains end, save (can be the start_node)
    if (foundStart && end < endCharCount && currentCharCount != end) {
      // Save reference to span node, create span wrapper if blank space
      if (textNodes[i].parentNode.parentNode === node) {
        end_node = document.createElement("span");
        end_node.innerHTML = textNodes[i].textContent;
        textNodes[i].parentNode.replaceChild(end_node, textNodes[i]);
      }
      else {
        end_node = textNodes[i].parentNode;
      }
      end_node_offset = end - currentCharCount;
      break;
    }
    currentCharCount = endCharCount;
  }

  // If only a single node, change text and insert two new spans before it
  if (start_node != null && end_node != null && start_node === end_node) {
    // Insert a plan node before where the glow should start
    var start_span_plain = start_node.clone(false);
    start_span_plain.innerHTML = start_node.textContent.substr(0, start_node_offset);
    start_node.innerHTML = start_node.textContent.substr(start_node_offset);

    // Maintain events
    if (start_node.hasClass("source_code_glowing_1")) {
      start_span_plain.addEventListener("mouseover", hover_on_function);
      start_span_plain.addEventListener("mouseout", hover_off_function);
    }

    // Insert the new plain span
    start_node.parentNode.insertBefore(start_span_plain, start_node);

    // Split and glow the rest
    this.splitAndGlowSpan(start_node, end_node_offset - start_node_offset, false,
      annotation_id, hover_on_function, hover_off_function);
  }
  else {
    if(start_node != null) {
      // Split the start node and set class/data/events
      this.splitAndGlowSpan(start_node, start_node_offset, true,
        annotation_id, hover_on_function, hover_off_function);
    }

    if (end_node != null) {
      // Split the end node and set class/data/events
      this.splitAndGlowSpan(end_node, end_node_offset, false,
        annotation_id, hover_on_function, hover_off_function);
    }
  }
}

// Split span node and apply class/data/events
// If glow_end is true, the glow will be after the original span
SourceCodeLine.prototype.splitAndGlowSpan= function(span_node, node_offset,
  glow_end, annotation_id, hover_on_function, hover_off_function) {

  var span_glow = span_node.clone(false);

  var glow_depth = span_glow.getAttribute("data-annotationDepth");
  span_glow.setAttribute("data-annotationDepth",
    glow_depth == null ? "1" : (parseInt(glow_depth, 10) + 1).toString());
  span_glow.setAttribute(
    "data-annotationID" + annotation_id.toString(), annotation_id.toString());

  span_glow.addClass('source_code_glowing_' +
  (glow_depth == null ? "1" : (parseInt(glow_depth, 10) + 1)));

  span_glow.addEventListener("mouseover", hover_on_function);
  span_glow.addEventListener("mouseout", hover_off_function);


  if (glow_end){
    span_glow.innerHTML = span_node.textContent.substr(node_offset);
    span_node.innerHTML = span_node.textContent.substr(0, node_offset);
    span_node.parentNode.insertBefore(span_glow, span_node.nextSibling)
  }
  else {
    span_glow.innerHTML = span_node.textContent.substr(0, node_offset);
    span_node.innerHTML = span_node.textContent.substr(node_offset);
    span_node.parentNode.insertBefore(span_glow, span_node);
  }
}

// Decrease a Source Code Line's glow depth
SourceCodeLine.prototype.unGlow = function(annotation_id) {
  // Is this line glowing?
  if (this.isGlowing()) {
    var textNodes = this.getAllTextNodes(this.getLineNode());

    // Create an array of glow nodes (spans)
    for (var i = 0; i < textNodes.length; i++) {
      if (textNodes[i].parentNode.getAttribute(
          "data-annotationID" + annotation_id.toString()) == annotation_id.toString()) {
        // Check and update the glow depth to handle nested annotations
        var glow_depth = textNodes[i].parentNode.getAttribute("data-annotationDepth");
        textNodes[i].parentNode.setAttribute(
          "data-annotationDepth",
          (parseInt(glow_depth, 10) - 1).toString());

        textNodes[i].parentNode.removeClass("source_code_glowing_" + glow_depth);

        // Remove mouse listeners if no longer glowing
        if(parseInt(glow_depth, 10)  == 1) {
          textNodes[i].parentNode.replaceChild(textNodes[i].clone(true), textNodes[i]);
        }
      }
    }
  }

  // Decrease the glow depth
  this.decGlowDepth(1);
}

// Recursive method returns an array of all text nodes contained in node param
SourceCodeLine.prototype.getAllTextNodes = function(node) {
  var textNodes = [];
  if (node.nodeType === 3) { // Push if text node
    textNodes.push(node);
  }
  else if(node.nodeType === 1) { // Recursively return all contained text nodes
    for (var i = 0; i < node.childNodes.length; i++) {
      textNodes.push.apply(textNodes, this.getAllTextNodes(node.childNodes[i]));
    }
  }
  return textNodes;
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

// ** I DONT THINK THIS IS BEING USED
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
