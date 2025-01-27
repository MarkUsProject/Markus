function getAllNodesInRange(range) {
  const start = range.startContainer;
  const end = range.endContainer;

  if (start === end) {
    return [start];
  }

  const commonAncestor = range.commonAncestorContainer;
  let start_prime = start;
  let end_prime = end;
  const start_ancestors = [];
  const end_ancestors = [];
  const between_primes = [];

  if (start !== commonAncestor) {
    while (start_prime.parentElement && start_prime.parentElement !== commonAncestor) {
      let next_sibling = start_prime.nextSibling;
      while (next_sibling) {
        start_ancestors.push(next_sibling);
        next_sibling = next_sibling.nextSibling;
      }
      start_prime = start_prime.parentElement;
    }
  }
  if (end !== commonAncestor) {
    while (end_prime.parentElement && end_prime.parentElement !== commonAncestor) {
      let prev_sibling = end_prime.previousSibling;
      while (prev_sibling) {
        end_ancestors.push(prev_sibling);
        prev_sibling = prev_sibling.previousSibling;
      }
      end_prime = end_prime.parentElement;
    }
  }

  while (start_prime && start_prime.nextSibling !== end_prime) {
    between_primes.push(start_prime.nextSibling);
    start_prime = start_prime.nextSibling;
  }
  return [start].concat(start_ancestors, between_primes, end_ancestors, [end]);
}

function getLeafNodes(root, _nodes) {
  _nodes = _nodes || [];
  let child = root.firstChild;
  if (!child) {
    _nodes.push(root);
  }
  while (child) {
    getLeafNodes(child, _nodes);
    child = child.nextSibling;
  }
  return _nodes;
}

export function pathToNode(node) {
  if (node.id) {
    return `//*[@id="${node.id}"]`;
  } else if (node.parentNode) {
    if (node.nodeType === Node.TEXT_NODE) {
      const index = [...node.parentNode.childNodes]
        .filter(n => n.nodeType === Node.TEXT_NODE)
        .indexOf(node);
      return `${pathToNode(node.parentNode)}/text()[${index + 1}]`;
    } else {
      const index = [...node.parentNode.childNodes]
        .filter(n => n.tagName === node.tagName)
        .indexOf(node);
      return `${pathToNode(node.parentNode)}/${node.tagName}[${index + 1}]`;
    }
  } else {
    return "";
  }
}

function addMouseOverToNode(node, content) {
  const content_container = node.ownerDocument.createElement("div");
  Object.assign(content_container.style, {
    display: "none",
    // copy of the css properties for .annotation_text_display elements
    background: document.documentElement.style.getPropertyValue("--background_main"),
    border: `1px solid ${document.documentElement.style.getPropertyValue("--sharp_line")}`,
    borderRadius: getComputedStyle(document.documentElement).getPropertyValue("--radius"),
    boxShadow: `4px 4px 2px ${document.documentElement.style.getPropertyValue("--primary_two")}`,
    maxWidth: "400px",
    padding: "0.25em 1em",
    position: "absolute",
    width: "auto",
    wordWrap: "break-word",
    zIndex: "100000",
  });
  content_container.innerHTML = safe_marked(content);
  content_container.className = "markus-annotation-content";
  node.ownerDocument.body.appendChild(content_container);
  node.addEventListener("mouseenter", e => {
    // We make MathJax typesetting lazy to avoid rendering issues when editing an annotation
    // from the "Annotations" tab, where the HTMLViewer component is updated before being visible.
    node.ownerDocument.defaultView.MathJax.typeset([content_container]);
    let offset_height = 0;
    for (let elem of node.ownerDocument.getElementsByClassName("markus-annotation-content")) {
      if (getComputedStyle(elem).display !== "none") {
        offset_height += elem.offsetHeight;
      }
    }
    content_container.style.left = `${e.pageX}px`;
    content_container.style.top = `${e.pageY + offset_height}px`;
    content_container.style.display = "";
  });
  node.addEventListener("mouseleave", () => {
    content_container.style.display = "none";
  });
}

export function markupTextInRange(range, content, id) {
  let existing_node = range.startContainer.ownerDocument.getElementById(`markus-annotation-${id}`);
  if (existing_node !== null) {
    let existing_parent = existing_node.parentNode;
    let replace_node = existing_node.cloneNode(true); // Create a deep copy
    existing_parent.replaceChild(replace_node, existing_node);
    addMouseOverToNode(replace_node, content);
    return;
  }
  if (range.startContainer === range.endContainer) {
    const old_node = range.startContainer;
    const parent = old_node.parentNode;
    let new_node;
    if (old_node.nodeType === Node.TEXT_NODE) {
      new_node = document.createElement("span");
      new_node.className = "markus-annotation";
      new_node.id = `markus-annotation-${id}`;
      const unmarked1 = document.createTextNode(old_node.nodeValue.substring(0, range.startOffset));
      const marked = document.createTextNode(
        old_node.nodeValue.substring(range.startOffset, range.endOffset)
      );
      const unmarked2 = document.createTextNode(old_node.nodeValue.substring(range.endOffset));
      new_node.appendChild(marked);
      parent.replaceChild(unmarked1, old_node);
      parent.insertBefore(new_node, unmarked1.nextSibling);
      parent.insertBefore(unmarked2, new_node.nextSibling);
    } else if (old_node.nodeName === "img" || old_node.childNodes.length) {
      new_node = document.createElement("div");
      new_node.className = "markus-annotation";
      new_node.id = `markus-annotation-${id}`;
      new_node.appendChild(old_node.cloneNode(true));
      parent.replaceChild(new_node, old_node);
    }
    addMouseOverToNode(new_node, content);
  } else {
    getAllNodesInRange(range).forEach(node => {
      getLeafNodes(node).forEach(old_node => {
        const parent = old_node.parentNode;
        let new_node;
        if (old_node.nodeType === Node.TEXT_NODE) {
          new_node = document.createElement("span");
          new_node.className = "markus-annotation";
          new_node.id = `markus-annotation-${id}`;
          if (old_node === range.startContainer) {
            const unmarked = document.createTextNode(
              old_node.nodeValue.substring(0, range.startOffset)
            );
            const marked = document.createTextNode(old_node.nodeValue.substring(range.startOffset));
            new_node.appendChild(marked);
            parent.replaceChild(unmarked, old_node);
            parent.insertBefore(new_node, unmarked.nextSibling);
          } else if (old_node === range.endContainer) {
            const marked = document.createTextNode(
              old_node.nodeValue.substring(0, range.endOffset)
            );
            const unmarked = document.createTextNode(old_node.nodeValue.substring(range.endOffset));
            new_node.appendChild(marked);
            parent.replaceChild(new_node, old_node);
            parent.insertBefore(unmarked, new_node.nextSibling);
          } else {
            new_node.appendChild(document.createTextNode(old_node.nodeValue));
            parent.replaceChild(new_node, old_node);
          }
        } else if (old_node.nodeName === "img" || old_node.childNodes.length) {
          new_node = document.createElement("div");
          new_node.className = "markus-annotation";
          new_node.id = `markus-annotation-${id}`;
          new_node.appendChild(old_node.cloneNode(true));
          parent.replaceChild(new_node, old_node);
        }
        addMouseOverToNode(new_node, content);
      });
    });
  }
}
