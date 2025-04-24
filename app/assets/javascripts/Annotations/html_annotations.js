/**
 * Functions for HTML (notebook) annotations
 */
function descendant_of_annotation(node) {
  if (node.nodeType === Node.DOCUMENT_NODE) {
    return false;
  } else if (node.className === "markus-annotation") {
    return true;
  } else {
    return descendant_of_annotation(node.parentNode);
  }
}

function ancestor_of_annotation(node) {
  if (node.nodeType === Node.TEXT_NODE) {
    node = node.parentNode;
  }
  return !!node.getElementsByClassName("markus-annotation").length;
}

function check_annotation_overlap(range) {
  let nodes;
  if (range.startContainer === range.endContainer) {
    nodes = [range.startContainer];
  } else {
    nodes = [range.startContainer, range.endContainer, range.commonAncestorContainer];
  }
  return (
    Array.from(range.cloneContents().children).some(node => ancestor_of_annotation(node)) ||
    nodes.some(node => descendant_of_annotation(node))
  );
}

function get_html_annotation_range() {
  const iframe = document.getElementById("html-content");
  const target = iframe.contentDocument;
  const selection = target.getSelection();
  if (selection.rangeCount >= 1) {
    const range = selection.getRangeAt(0);
    if (check_annotation_overlap(range)) {
      alert(I18n.t("results.annotation.no_overlap"));
      return {};
    }
    if (range.startOffset !== range.endOffset || range.startContainer !== range.endContainer) {
      return range;
    }
  }
  alert(I18n.t("results.annotation.select_some_text"));
  return {};
}
