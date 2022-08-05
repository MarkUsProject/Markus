/**
 * AnnotationManager subclass for plaintext files. Its constructor is given a list of DOM elements
 * (one for each line of text in the file), that have been transformed through SyntaxHighlighter.
 */
class TextAnnotationManager extends AnnotationManager {
  constructor(source_nodes) {
    super();

    this.source_lines = [null]; // Include dummy value because source code lines are 1-indexed
    for (let source_node of source_nodes) {
      this.source_lines.push(new SourceCodeLine(source_node));
    }
  }

  /**
   * Add the given annotation to a range of source code lines.
   */
  addAnnotation(annotation_text_id, content, range, annotation_id) {
    super.addAnnotation(annotation_text_id, content, range, annotation_id);

    let lineStart = range.start;
    let lineEnd = range.end;
    if (lineStart < 0 || lineEnd < 0) return;

    let columnStart = range.column_start;
    let columnEnd = range.column_end;

    // Annotate lines from lineStart to lineEnd, *inclusive*
    for (
      let lineNum = lineStart;
      lineNum <= Math.min(lineEnd, this.source_lines.length - 1);
      lineNum++
    ) {
      this.annotateLine(
        annotation_id,
        lineNum,
        lineNum === lineStart ? columnStart : 0,
        lineNum === lineEnd ? columnEnd : -1 // -1 is used to represent the end of the line
      );
    }
  }

  /**
   * Add annotation to a single line of source code. This is intended as a private method;
   * addAnnotation should be called from external code.
   */
  annotateLine(annotationId, lineNum, columnStart, columnEnd) {
    let line = this.source_lines[lineNum];

    // Add the annotation
    line.glow(
      annotationId,
      columnStart,
      columnEnd,
      event => {
        this.displayTextsForLine(lineNum, event, event.pageX, event.pageY);
      },
      () => {
        this.annotation_text_displayer.hide();
      }
    );
  }

  displayTextsForLine(lineNum, event, x, y) {
    let texts = [];
    let source = event.currentTarget ? event.currentTarget : event.srcElement;
    for (let attribute of source.attributes) {
      if (attribute.name.indexOf("data-annotationid") >= 0) {
        texts.push(this.annotations[attribute.value].annotation_text);
      }
    }

    this.annotation_text_displayer.displayCollection(texts, x, y);
  }

  /**
   * Removes the given annotation from the given range.
   */
  removeAnnotation(annotation_id) {
    let annotation = super.removeAnnotation(annotation_id);
    for (let line_num = annotation.range.start; line_num <= annotation.range.end; line_num++) {
      let line = this.source_lines[line_num];
      line.unGlow(annotation_id);

      if (
        !Object.values(this.annotations).some(
          ({range}) => range.start <= line_num && line_num <= range.end
        )
      ) {
        line.stopObserving();
      }
    }
  }

  /**
   * Returns the current text selection range
   * @returns {{line_start, line_end, column_start, column_end}}
   */
  getSelection(warn_no_selected = true) {
    let mouseSelection = window.getSelection();
    let mouse_anchor = mouseSelection.anchorNode;
    let mouse_focus = mouseSelection.focusNode;

    if (mouse_anchor === null || mouse_focus === null) {
      if (warn_no_selected) {
        alert(I18n.t("results.annotation.select_some_text"));
      }
      return false;
    }

    // Use the adapter to get the nodes that represent source code lines, and translate to line numbers
    let anchor_node = this.getRootFromSelection(mouse_anchor);
    let focus_node = this.getRootFromSelection(mouse_focus);
    let line_start = this.source_lines.findIndex(
      line => line !== null && line.line_node === anchor_node
    );
    let line_end = this.source_lines.findIndex(
      line => line !== null && line.line_node === focus_node
    );

    // If the entire line was selected through a triple-click, highlight the entire line.
    if (mouse_anchor.nodeName === "LI" && mouse_focus.nodeName === "LI") {
      return {
        line_start: line_start,
        line_end: line_end,
        column_start: 0,
        column_end: mouse_focus.textContent.length,
      };
    }

    // If we selected an entire line the above returns + 1, a fix follows
    if (mouseSelection.anchorNode.nodeName === "LI") {
      line_start--;
    }
    if (mouseSelection.focusNode.nodeName === "LI") {
      line_end--;
    }

    // If no source code lines were selected, bail out
    if (line_start < 0 || line_end < 0 || (line_start === 0 && line_end === 0)) {
      if (warn_no_selected) {
        alert(I18n.t("results.annotation.select_some_text"));
      }
      return false;
    }

    // Add up node lengths to get column offsets
    let anchor_line_span;
    if (mouseSelection.anchorNode.parentNode.parentNode.nodeName === "SPAN") {
      anchor_line_span = mouseSelection.anchorNode.parentNode.parentNode;
    } else {
      anchor_line_span = mouseSelection.anchorNode.parentNode;
    }

    let column_start = 0;
    for (let child of anchor_line_span.childNodes) {
      if (child === mouseSelection.anchorNode.parentNode || child === mouseSelection.anchorNode) {
        // If the actual node add the offset
        column_start += mouseSelection.anchorOffset;
        break;
      } else {
        // If just a lead up node add the entire length
        column_start += child.textContent.length;
      }
    }

    // Repeat the same process for the focus node
    let focus_line_span;
    if (mouseSelection.focusNode.parentNode.parentNode.nodeName === "SPAN") {
      focus_line_span = mouseSelection.focusNode.parentNode.parentNode;
    } else {
      focus_line_span = mouseSelection.focusNode.parentNode;
    }
    let column_end = 0;
    for (let child of focus_line_span.childNodes) {
      if (child === mouseSelection.focusNode.parentNode || child === mouseSelection.focusNode) {
        column_end += mouseSelection.focusOffset;
        break;
      } else {
        column_end += child.textContent.length;
      }
    }

    // If only one valid source code line was selected, we'll only highlight
    // that one.  This is for the case where you highlight the first line, and
    // then focus some text outside of the source code as well.
    if (line_start === 0 && line_end !== 0) {
      line_start = line_end;
    } else if (line_start !== 0 && line_end === 0) {
      line_end = line_start;
    } else if (line_start > line_end) {
      // If line_start > line_end, swap line and column
      [line_start, line_end] = [line_end, line_start];
      [column_start, column_end] = [column_end, column_start];
    } else if (line_start === line_end && column_start > column_end) {
      // If one line is selected and column_start > column_end, swap the columns
      [column_start, column_end] = [column_end, column_start];
    }

    if (line_start === line_end && column_start === column_end) {
      if (warn_no_selected) {
        alert(I18n.t("results.annotation.select_some_text"));
      }
      return false;
    }

    return {
      line_start: line_start,
      line_end: line_end,
      column_start: column_start,
      column_end: column_end,
    };
  }

  // Given some node, traverses upwards until it finds the LI element that represents a line of code in SyntaxHighlighter.
  // This is useful for figuring out what text is currently selected, using window.getSelection().anchorNode / focusNode
  getRootFromSelection(node) {
    let current_node = node;
    while (current_node !== null && current_node.tagName !== "LI") {
      current_node = current_node.parentNode;
    }
    return current_node;
  }
}
