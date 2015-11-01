/** Source Code Line Class

    This class represents a single line of source code, and controls "glowing",
    and mouseover/mouseout observing.  It's an abstract class that needs to be
    implemented for the particular source code highlighting library being used

    Rules:
    - When a span is "glowing", it has a class of "source-code-glowing-" and
      then a number indicating the "depth" of its glow.  This allows for
      annotation overlapping. For example, 5 lines of source could be
      "glowed", and then three lines within that original 5 could be glowed
      again - their glow depth will increase.
    - Each span will have data attributes added to allow for depth tracking and
      to enable unglowing with overlapping annotations
    - This is an abstract class that needs to be implemented for the particular
      source code highlighting library being used
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
SourceCodeLine.prototype.glow = function(annotationId, start, end,
  hoverOnFunction, hoverOffFunction) {
  // Increase the depth and turn on design mode for highlighting
  this.incGlowDepth(1);

  // Save line node and get all text nodes in the line
  var node = this.getLineNode();
  var textNodes = this.getAllTextNodes(node);
  if (end == -1){
    end = this.getLineNode().textContent.length;
  }

  // Loop prep, for tracking nodes and character counts
  var startNode = null;
  var startNodeOffset = 0;
  var endNode = null;
  var endNodeOffset = 0;
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
          startNode = document.createElement("span");
          startNode.innerHTML = textNodes[i].textContent;
          textNodes[i].parentNode.replaceChild(startNode, textNodes[i]);
          textNodes[i] = startNode.childNodes[0];
        }
        else {
          startNode = textNodes[i].parentNode;
        }
        startNodeOffset = start - currentCharCount;
      }
    }
    // Adds class/data/events to the nodes between the start and end
    else if (foundStart && end >= endCharCount) {
      // Make sure it has its own parent span
      if (textNodes[i].parentNode.parentNode === node) {
        var tempNode = document.createElement("span");
        tempNode.innerHTML = textNodes[i].textContent;
        textNodes[i].parentNode.replaceChild(tempNode, textNodes[i]);
        textNodes[i] = tempNode.childNodes[0];
      }
      var glowDepth = textNodes[i].parentNode.getAttribute(
        "data-annotationDepth");
      textNodes[i].parentNode.setAttribute("data-annotationDepth",
        glowDepth === null ? "1" : (parseInt(glowDepth, 10) + 1).toString());
      textNodes[i].parentNode.setAttribute("data-annotationID" +
        annotationId.toString(), annotationId.toString());

      textNodes[i].parentNode.addClass("source-code-glowing-" +
        (glowDepth === null ? "1" : (parseInt(glowDepth, 10) + 1)));

      textNodes[i].parentNode.addEventListener("mouseover", hoverOnFunction);
      textNodes[i].parentNode.addEventListener("mouseout", hoverOffFunction);
    }

    // If foundStart & current node contains end, save (can be the startNode)
    if (foundStart && end < endCharCount && currentCharCount != end) {
      // Save reference to span node, create span wrapper if blank space
      if (textNodes[i].parentNode.parentNode === node) {
        endNode = document.createElement("span");
        endNode.innerHTML = textNodes[i].textContent;
        textNodes[i].parentNode.replaceChild(endNode, textNodes[i]);
      }
      else {
        endNode = textNodes[i].parentNode;
      }
      endNodeOffset = end - currentCharCount;
      break;
    }
    currentCharCount = endCharCount;
  }

  // If only a single node, change text and insert two new spans before it
  if (startNode !== null && endNode !== null && startNode === endNode) {
    // Insert a plan node before where the glow should start
    var startSpanPlain = jQuery(startNode).clone(false)[0];
    startSpanPlain.innerHTML = startNode.textContent.substr(0, startNodeOffset);
    startNode.innerHTML = startNode.textContent.substr(startNodeOffset);

    // Maintain events
    if (startNode.hasClass("source-code-glowing-1")) {
      startSpanPlain.addEventListener("mouseover", hoverOnFunction);
      startSpanPlain.addEventListener("mouseout", hoverOffFunction);
    }

    // Insert the new plain span
    startNode.parentNode.insertBefore(startSpanPlain, startNode);

    // Split and glow the rest
    this.splitAndGlowSpan(startNode, endNodeOffset - startNodeOffset, false,
      annotationId, hoverOnFunction, hoverOffFunction);
  }
  else {
    if(startNode !== null) {
      // Split the start node and set class/data/events
      this.splitAndGlowSpan(startNode, startNodeOffset, true,
        annotationId, hoverOnFunction, hoverOffFunction);
    }

    if (endNode !== null) {
      // Split the end node and set class/data/events
      this.splitAndGlowSpan(endNode, endNodeOffset, false,
        annotationId, hoverOnFunction, hoverOffFunction);
    }
  }
};

// Split span node and apply class/data/events
// If glow_end is true, the glow will be after the original span
SourceCodeLine.prototype.splitAndGlowSpan= function(spanNode, nodeOffset,
  glowEnd, annotationId, hoverOnFunction, hoverOffFunction) {

  var spanGlow = jQuery(spanNode).clone(false)[0];

  var glowDepth = spanGlow.getAttribute("data-annotationDepth");
  spanGlow.setAttribute("data-annotationDepth",
    glowDepth === null ? "1" : (parseInt(glowDepth, 10) + 1).toString());
  spanGlow.setAttribute(
    "data-annotationID" + annotationId.toString(), annotationId.toString());

  spanGlow.addClass("source-code-glowing-" +
  (glowDepth === null ? "1" : (parseInt(glowDepth, 10) + 1)));

  spanGlow.addEventListener("mouseover", hoverOnFunction);
  spanGlow.addEventListener("mouseout", hoverOffFunction);


  if (glowEnd){
    spanGlow.innerHTML = spanNode.textContent.substr(nodeOffset);
    spanNode.innerHTML = spanNode.textContent.substr(0, nodeOffset);
    spanNode.parentNode.insertBefore(spanGlow, spanNode.nextSibling);
  }
  else {
    spanGlow.innerHTML = spanNode.textContent.substr(0, nodeOffset);
    spanNode.innerHTML = spanNode.textContent.substr(nodeOffset);
    spanNode.parentNode.insertBefore(spanGlow, spanNode);
  }
}

// Decrease a Source Code Line's glow depth
SourceCodeLine.prototype.unGlow = function(annotationId) {
  // Is this line glowing?
  if (this.isGlowing()) {
    var textNodes = this.getAllTextNodes(this.getLineNode());

    // Create an array of glow nodes (spans)
    for (var i = 0; i < textNodes.length; i++) {
      if (textNodes[i].parentNode.getAttribute("data-annotationID" +
        annotationId.toString()) === annotationId.toString()) {
        // Check and update the glow depth to handle nested annotations
        var glowDepth = textNodes[i].parentNode.getAttribute(
          "data-annotationDepth");
        textNodes[i].parentNode.setAttribute(
          "data-annotationDepth",
          (parseInt(glowDepth, 10) - 1).toString());

        textNodes[i].parentNode.removeClass("source-code-glowing-" + glowDepth);

        // Remove mouse listeners if no longer glowing
        if(parseInt(glowDepth, 10) === 1) {
          textNodes[i].parentNode.parentNode.replaceChild(
            jQuery(textNodes[i].parentNode).clone(true)[0], textNodes[i].parentNode);
        }
      }
    }
  }

  // Decrease the glow depth
  this.decGlowDepth(1);
};

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
};

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
