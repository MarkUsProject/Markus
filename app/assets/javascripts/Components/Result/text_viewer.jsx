import React from "react";
import {render} from "react-dom";

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
    if (this.highlight_root !== null) {
      this.highlight_root.remove();
    }
    if (this.annotation_manager !== null) {
      this.annotation_manager.annotation_text_displayer.hide();
    }

    const preElementName = this.raw_content.current.getAttribute("name");
    dp.SyntaxHighlighter.HighlightAll(
      preElementName,
      true /* showGutter */,
      false /* showControls */
    );
    this.highlight_root =
      this.raw_content.current.parentNode.getElementsByClassName("dp-highlighter")[0];
    this.highlight_root.style.font_size = this.state.fontSize + "em";

    if (this.props.resultView) {
      window.annotation_type = ANNOTATION_TYPES.CODE;

      window.annotation_manager = new TextAnnotationManager(
        this.highlight_root.children[1].children
      );
      this.annotation_manager = window.annotation_manager;
    }

    this.props.annotations.forEach(this.display_annotation);
    this.scrollToLine(this.props.focusLine);
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

    this.annotation_manager.addAnnotation(
      annotation.annotation_text_id,
      content,
      {
        start: parseInt(annotation.line_start, 10),
        end: parseInt(annotation.line_end, 10),
        column_start: parseInt(annotation.column_start, 10),
        column_end: parseInt(annotation.column_end, 10),
      },
      annotation.id
    );
  };

  // Scroll to display the given line.
  scrollToLine = lineNumber => {
    if (this.highlight_root === null || lineNumber === undefined || lineNumber === null) {
      return;
    }

    const line = this.highlight_root.querySelector(`li:nth-of-type(${lineNumber})`);
    if (line) {
      line.scrollIntoView();
    }
  };

  componentWillUnmount() {
    document.querySelectorAll(".dp-highlighter").forEach(node => node.remove());
  }

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
            <a href="#" onClick={() => dp.sh.Toolbar.Command("About", this.highlight_root)}>
              ?
            </a>
          </div>
        </div>
        <pre name={preElementName} ref={this.raw_content} className={this.props.type}>
          {this.props.content}
        </pre>
      </React.Fragment>
    );
  }
}
