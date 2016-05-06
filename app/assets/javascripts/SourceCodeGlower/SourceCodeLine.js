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
      to enable unglowing with overlapping annotations.
*/

function SourceCodeLine(line_node) {
  // line_node is the DOM element that holds a line of source code
  this.line_node         = line_node;
  this.glow_depth        = 0;
  this.observe_over_func = null;
  this.observe_out_func  = null;
  this.is_observing      = false;
}

// Increase a Source Code Line's glow depth, add listeners.
// Adds annotation at text positions start..(end - 1),
// splitting nodes if needed.
SourceCodeLine.prototype.glow = function(annotationId, start, end,
  hoverOnFunction, hoverOffFunction) {
  if (end === -1) {
    end = this.line_node.textContent.length;
  }

  if (start >= end) {
    console.error('Bad annotation with start ' + start + ' and end ' + end);
    return;
  }
  // Increase the glow depth
  this.incGlowDepth(1);

  // Save line node and get all text nodes in the line
  var node = this.line_node;
  var textNodes = getAllTextNodes(node);

  // Loop prep, for tracking nodes and character counts
  var startNode = null;
  var startNodeOffset = 0;
  var endNode = null;
  var endNodeOffset = 0;
  var currentCharCount = 0;
  var endCharCount = 0;
  var parent = null;

  // Loop over nodes, add length of passed nodes, save start and end then break
  for (var i = 0; i < textNodes.length; i++) {
    // End char offset of the current text node
    endCharCount = currentCharCount + textNodes[i].length;
    parent = textNodes[i].parentNode;

    if (start >= currentCharCount && start < endCharCount) {
      // Current node is the start of the annotation, so save it.
      // NOTE: if endCharCount === start, start glowing the next node.

      // Will need to split the node if the glow starts inside of it
      if (parent.parentNode === node) {
        startNode = document.createElement('span');
        startNode.textContent = textNodes[i].textContent;
        parent.replaceChild(startNode, textNodes[i]);
        textNodes[i] = startNode.childNodes[0];
      } else {
        startNode = parent;
      }
      startNodeOffset = start - currentCharCount;
    } else if (start < currentCharCount && end > endCharCount) {
      // Current node is in the middle of the annotation.
      if (parent.parentNode === node) {
        var tempNode = document.createElement('span');
        tempNode.textContent = textNodes[i].textContent;
        parent.replaceChild(tempNode, textNodes[i]);
        textNodes[i] = tempNode.childNodes[0];
      }
      parent.setAttribute('data-annotationID' + annotationId, annotationId);

      var glowDepth = parent.getAttribute('data-annotationDepth');
      var newGlowDepth;
      if (glowDepth === null) {
        newGlowDepth = '1';
      } else {
        newGlowDepth = (parseInt(glowDepth, 10) + 1).toString();
      }
      parent.setAttribute('data-annotationDepth', newGlowDepth);
      parent.addClass('source-code-glowing-' + newGlowDepth);
      parent.addEventListener('mouseover', hoverOnFunction);
      parent.addEventListener('mouseout', hoverOffFunction);
    }

    // If current node contains end, save (can be the startNode).
    if (end <= endCharCount) {
      // Save reference to span node, create span wrapper if blank space
      if (start >= currentCharCount) {
        endNode = startNode;
      } else if (parent.parentNode === node) {
        endNode = document.createElement('span');
        endNode.textContent = textNodes[i].textContent;
        parent.replaceChild(endNode, textNodes[i]);
      } else {
        endNode = parent;
      }
      endNodeOffset = end - currentCharCount;
      break;
    }
    currentCharCount = endCharCount;
  }

  if (startNode === null || endNode === null) {
    console.error('Bad annotation with start ' + start + ' and end ' + end);
    return;
  }

  // If only a single node, change text and insert two new spans before it
  if (startNode === endNode) {
    if (startNodeOffset > 0) {
      // Insert a plain node before where the glow should start
      var startSpanPlain = jQuery(startNode).clone(false)[0];
      startSpanPlain.textContent = startNode.textContent.substr(0, startNodeOffset);
      startNode.textContent = startNode.textContent.substr(startNodeOffset);

      // Maintain events
      if (startSpanPlain.hasClass('source-code-glowing-1')) {
        startSpanPlain.addEventListener('mouseover', hoverOnFunction);
        startSpanPlain.addEventListener('mouseout', hoverOffFunction);
      }

      startNode.parentNode.insertBefore(startSpanPlain, startNode);
    }

    // Split and glow the rest
    this.splitAndGlowSpan(startNode, endNodeOffset - startNodeOffset, false,
      annotationId, hoverOnFunction, hoverOffFunction);
  } else {
    // Split the start node and set class/data/events
    this.splitAndGlowSpan(startNode, startNodeOffset, true,
      annotationId, hoverOnFunction, hoverOffFunction);

    // Split the end node and set class/data/events
    this.splitAndGlowSpan(endNode, endNodeOffset, false,
      annotationId, hoverOnFunction, hoverOffFunction);
  }
};

// Split span node and apply class/data/events
// If glow_end is true, the glow will be after the original span
SourceCodeLine.prototype.splitAndGlowSpan = function(spanNode, nodeOffset,
  glowEnd, annotationId, hoverOnFunction, hoverOffFunction) {
  var spanGlow = jQuery(spanNode).clone(false)[0];

  var glowDepth = spanGlow.getAttribute('data-annotationDepth');
  var newGlowDepth;
  if (glowDepth === null) {
    newGlowDepth = '1';
  } else {
    newGlowDepth = (parseInt(glowDepth, 10) + 1).toString();
  }
  spanGlow.setAttribute('data-annotationDepth', newGlowDepth);
  spanGlow.setAttribute('data-annotationID' + annotationId, annotationId);
  spanGlow.addClass('source-code-glowing-' + newGlowDepth);

  spanGlow.addEventListener('mouseover', hoverOnFunction);
  spanGlow.addEventListener('mouseout', hoverOffFunction);

  if ((glowEnd && nodeOffset <= 0) ||
      (!glowEnd && nodeOffset >= spanNode.textContent.length)) {
    spanNode.parentNode.replaceChild(spanGlow, spanNode);
  } else if (glowEnd) {
    spanGlow.textContent = spanNode.textContent.substr(nodeOffset);
    spanNode.textContent = spanNode.textContent.substr(0, nodeOffset);
    spanNode.parentNode.insertBefore(spanGlow, spanNode.nextSibling);
  } else {
    spanGlow.textContent = spanNode.textContent.substr(0, nodeOffset);
    spanNode.textContent = spanNode.textContent.substr(nodeOffset);
    spanNode.parentNode.insertBefore(spanGlow, spanNode);
  }
};

// Decrease a Source Code Line's glow depth
SourceCodeLine.prototype.unGlow = function(annotationId) {
  // Is this line glowing?
  if (this.isGlowing()) {
    var textNodes = getAllTextNodes(this.line_node);

    for (var i = 0; i < textNodes.length; i++) {
      var parent = textNodes[i].parentNode;
      if (parent.getAttribute('data-annotationID' + annotationId) ===
          annotationId) {
        // Check and update the glow depth to handle nested annotations
        var glowDepth = parent.getAttribute(
          'data-annotationDepth');
        parent.setAttribute(
          'data-annotationDepth',
          (parseInt(glowDepth, 10) - 1).toString());

        parent.removeClass('source-code-glowing-' + glowDepth);

        // Remove mouse listeners if no longer glowing
        if (parseInt(glowDepth, 10) === 1) {
          parent.parentNode.replaceChild(
            jQuery(parent).clone(true)[0], parent);
        }
      }
    }
    this.decGlowDepth(1);
  }
};

// Recursive function returns an array of all text nodes contained in node
function getAllTextNodes(node) {
  var textNodes = [];
  if (node.nodeType === 3) { // Push if text node
    textNodes.push(node);
  } else if (node.nodeType === 1) { // Recurse on all children
    for (var i = 0; i < node.childNodes.length; i++) {
      textNodes = textNodes.concat(getAllTextNodes(node.childNodes[i]));
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
