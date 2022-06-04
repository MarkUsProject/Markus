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

class SourceCodeLine {
  constructor(line_node) {
    // line_node is the DOM element that holds a line of source code
    this.line_node = line_node;
    this.glow_depth = 0;
    this.is_observing = false;
  }

  // Increase a Source Code Line's glow depth, add listeners.
  // Adds annotation at text positions start..(end - 1),
  // splitting nodes if needed.
  glow(annotationId, start, end, hoverOnFunction, hoverOffFunction) {
    if (end === -1) {
      end = this.line_node.textContent.length;
    }

    if (start >= end) {
      console.error("Bad annotation with start " + start + " and end " + end);
      return;
    }
    // Increase the glow depth
    this.glow_depth += 1;

    // Save line node and get all text nodes in the line
    let node = this.line_node;
    let textNodes = getAllTextNodes(node);

    // Loop prep, for tracking nodes and character counts
    let startNode = null;
    let startNodeOffset = 0;
    let endNode = null;
    let endNodeOffset = 0;
    let currentCharCount = 0;

    // Loop over nodes, add length of passed nodes, save start and end then break
    for (let i = 0; i < textNodes.length; i++) {
      // End char offset of the current text node
      let endCharCount = currentCharCount + textNodes[i].length;
      let parent = textNodes[i].parentNode;

      if (start >= currentCharCount && start < endCharCount) {
        // Current node is the start of the annotation, so save it.
        // NOTE: if endCharCount === start, start glowing the next node.

        // Will need to split the node if the glow starts inside of it
        if (parent.parentNode === node) {
          startNode = document.createElement("span");
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
          let tempNode = document.createElement("span");
          tempNode.textContent = textNodes[i].textContent;
          parent.replaceChild(tempNode, textNodes[i]);
          textNodes[i] = tempNode.childNodes[0];
        }
        annotationId = annotationId.toString();
        parent.setAttribute("data-annotationID" + annotationId, annotationId);

        let glowDepth = parent.getAttribute("data-annotationDepth");
        let newGlowDepth;
        if (glowDepth === null) {
          newGlowDepth = "1";
        } else {
          newGlowDepth = (parseInt(glowDepth, 10) + 1).toString();
        }
        parent.setAttribute("data-annotationDepth", newGlowDepth);
        parent.addClass("source-code-glowing-" + newGlowDepth);
        parent.addEventListener("mouseover", hoverOnFunction);
        parent.addEventListener("mouseout", hoverOffFunction);
      }

      // If current node contains end, save (can be the startNode).
      if (end <= endCharCount) {
        // Save reference to span node, create span wrapper if blank space
        if (start >= currentCharCount) {
          endNode = startNode;
        } else if (parent.parentNode === node) {
          endNode = document.createElement("span");
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
      if (endNode === null && startNode !== null) {
        endNode = startNode;
      } else {
        console.error("Bad annotation with start " + start + " and end " + end);
        return;
      }
    }

    // If only a single node, change text and insert two new spans before it
    if (startNode === endNode) {
      if (startNodeOffset > 0) {
        // Insert a plain node before where the glow should start
        var startSpanPlain = $(startNode).clone(false)[0];
        startSpanPlain.textContent = startNode.textContent.substr(0, startNodeOffset);
        startNode.textContent = startNode.textContent.substr(startNodeOffset);

        // Maintain events
        if (startSpanPlain.hasClass("source-code-glowing-1")) {
          startSpanPlain.addEventListener("mouseover", hoverOnFunction);
          startSpanPlain.addEventListener("mouseout", hoverOffFunction);
        }

        startNode.parentNode.insertBefore(startSpanPlain, startNode);
      }

      // Split and glow the rest
      this.splitAndGlowSpan(
        startNode,
        endNodeOffset - startNodeOffset,
        false,
        annotationId,
        hoverOnFunction,
        hoverOffFunction
      );
    } else {
      // Split the start node and set class/data/events
      this.splitAndGlowSpan(
        startNode,
        startNodeOffset,
        true,
        annotationId,
        hoverOnFunction,
        hoverOffFunction
      );

      // Split the end node and set class/data/events
      this.splitAndGlowSpan(
        endNode,
        endNodeOffset,
        false,
        annotationId,
        hoverOnFunction,
        hoverOffFunction
      );
    }
  }

  // Split span node and apply class/data/events
  // If glow_end is true, the glow will be after the original span
  splitAndGlowSpan(spanNode, nodeOffset, glowEnd, annotationId, hoverOnFunction, hoverOffFunction) {
    let spanGlow = $(spanNode).clone(false)[0];

    let glowDepth = spanGlow.getAttribute("data-annotationDepth");
    let newGlowDepth;
    if (glowDepth === null) {
      newGlowDepth = "1";
    } else {
      newGlowDepth = (parseInt(glowDepth, 10) + 1).toString();
    }
    spanGlow.setAttribute("data-annotationDepth", newGlowDepth);
    spanGlow.setAttribute("data-annotationID" + annotationId, annotationId);
    spanGlow.addClass("source-code-glowing-" + newGlowDepth);

    spanGlow.addEventListener("mouseover", hoverOnFunction);
    spanGlow.addEventListener("mouseout", hoverOffFunction);

    if ((glowEnd && nodeOffset <= 0) || (!glowEnd && nodeOffset >= spanNode.textContent.length)) {
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
  }

  // Decrease a Source Code Line's glow depth
  unGlow(annotationId) {
    // Do nothin if the line is not glowing
    if (this.glow_depth === 0) {
      return;
    }

    annotationId = annotationId.toString();
    let textNodes = getAllTextNodes(this.line_node);

    for (let textNode of textNodes) {
      let parent = textNode.parentNode;
      if (parent.getAttribute("data-annotationID" + annotationId) === annotationId) {
        // Check and update the glow depth to handle nested annotations
        let glowDepth = parseInt(parent.getAttribute("data-annotationDepth"), 10);
        parent.setAttribute("data-annotationDepth", (glowDepth - 1).toString());

        parent.removeClass("source-code-glowing-" + glowDepth);

        // Remove mouse listeners if no longer glowing
        if (glowDepth === 1) {
          parent.parentNode.replaceChild($(parent).clone(true)[0], parent);
        }
      }
    }
    this.glow_depth -= 1;
  }

  stopObserving() {
    // If we're not observing this, this isn't a problem
    if (!this.is_observing) {
      return;
    }

    this.line_node.onmouseover = null;
    this.line_node.onmouseout = null;
    this.is_observing = false;
  }
}

// Recursive function returns an array of all text nodes contained in node
function getAllTextNodes(node) {
  let textNodes = [];
  if (node.nodeType === 3) {
    // Push if text node
    textNodes.push(node);
  } else if (node.nodeType === 1) {
    // Recurse on all children
    for (let child of node.childNodes) {
      textNodes = textNodes.concat(getAllTextNodes(child));
    }
  }
  return textNodes;
}
