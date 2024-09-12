import React from "react";
import {render} from "react-dom";
import Prism from "prismjs";

export class TextViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      copy_success: false,
      font_size: 1,
    };
    this.highlight_root = null;
    this.annotation_manager = null;
    this.raw_content = React.createRef();
  }

  componentDidMount() {
    this.highlight_root = this.raw_content.current.parentNode;
    if (this.props.content) {
      this.ready_annotations();
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (
      this.props.content &&
      (this.props.content !== prevProps.content || this.props.annotations !== prevProps.annotations)
    ) {
      this.ready_annotations();
      this.setState({copy_success: false});
    } else if (this.props.focusLine !== prevProps.focusLine) {
      this.scrollToLine(this.props.focusLine);
    }
    if (prevState.font_size !== this.state.font_size && this.highlight_root !== null) {
      this.highlight_root.style.fontSize = this.state.font_size + "em";
    }
  }

  /**
   * Post-processes text contents and display in three ways:
   *
   * 1. Apply syntax highlighting
   * 2. Display annotations
   * 3. Scroll to line numbered this.props.focusLine
   */
  ready_annotations = () => {
    this.run_syntax_highlighting();

    if (this.annotation_manager !== null) {
      this.annotation_manager.annotation_text_displayer.hide();
    }

    this.highlight_root.style.font_size = this.state.fontSize + "em";

    if (this.props.resultView) {
      window.annotation_type = ANNOTATION_TYPES.CODE;

      window.annotation_manager = new TextAnnotationManager(this.raw_content.current.children);
      this.annotation_manager = window.annotation_manager;
    }

    this.props.annotations.forEach(this.display_annotation);
    this.scrollToLine(this.props.focusLine);
  };

  run_syntax_highlighting = () => {
    Prism.highlightElement(this.raw_content.current, false);
    let nodeLines = [];
    let currLine = document.createElement("span");
    currLine.classList.add("source-line");
    let currChildren = [];
    for (let node of this.raw_content.current.childNodes) {
      // Note: SourceCodeLine.glow assumes text nodes are wrapped in <span> elements
      let textContainer = document.createElement("span");
      let className = node.nodeType === Node.TEXT_NODE ? "" : node.className;
      textContainer.className = className;

      const splits = node.textContent.split("\n");
      for (let i = 0; i < splits.length - 1; i++) {
        textContainer.textContent = splits[i] + "\n";
        currLine.append(...currChildren, textContainer);
        nodeLines.push(currLine);
        currLine = document.createElement("span");
        currLine.classList.add("source-line");
        currChildren = [];
        textContainer = document.createElement("span");
        textContainer.className = className;
      }

      textContainer.textContent = splits[splits.length - 1];
      currLine.append(...currChildren, textContainer);
    }
    if (currLine.textContent.length > 0) {
      nodeLines.push(currLine);
    }
    this.raw_content.current.replaceChildren(
      ...nodeLines,
      this.raw_content.current.lastChild.cloneNode(true)
    );
  };

  change_font_size = delta => {
    this.setState({font_size: Math.max(this.state.font_size + delta, 0.25)});
  };

  display_annotation = annotation => {
    let content;
    if (!annotation.deduction) {
      content = annotation.content;
    } else {
      content =
        annotation.content + " [" + annotation.criterion_name + ": -" + annotation.deduction + "]";
    }

    if (annotation.is_remark) {
      content += ` (${I18n.t("results.annotation.remark_flag")})`;
    }

    this.annotation_manager.addAnnotation(
      annotation.annotation_text_id,
      content,
      {
        start: parseInt(annotation.line_start, 10),
        end: parseInt(annotation.line_end, 10),
        column_start: parseInt(annotation.column_start, 10),
        column_end: parseInt(annotation.column_end, 10),
      },
      annotation.id,
      annotation.is_remark
    );
  };

  // Scroll to display the given line.
  scrollToLine = lineNumber => {
    if (this.highlight_root === null || lineNumber === undefined || lineNumber === null) {
      return;
    }

    const line = this.highlight_root.querySelector(`span.source-line:nth-of-type(${lineNumber})`);
    if (line) {
      line.scrollIntoView();
    }
  };

  copyToClipboard = () => {
    navigator.clipboard.writeText(this.props.content).then(() => {
      this.setState({copy_success: true});
    });
  };

  render() {
    const preElementName = `code-${this.props.submission_file_id}`;

    return (
      <React.Fragment>
        <div className="toolbar">
          <div className="toolbar-actions">
            <a href="#" onClick={this.copyToClipboard}>
              {this.state.copy_success ? "✔ " : ""}
              {I18n.t("results.copy_text")}
            </a>
            <a href="#" onClick={() => this.change_font_size(0.25)}>
              +A
            </a>
            <a href="#" onClick={() => this.change_font_size(-0.25)}>
              -A
            </a>
          </div>
        </div>
        <pre name={preElementName} className={`line-numbers`}>
          <code ref={this.raw_content} className={`language-${this.props.type}`}>
            {this.props.content}
          </code>
        </pre>
      </React.Fragment>
    );
  }
}
