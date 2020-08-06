import React from 'react';
import {render} from 'react-dom';


const RAW_TEXT_DIV_ID = 'code';


export class TextViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidMount() {
    if (this.props.content) {
      this.ready_annotations(RAW_TEXT_DIV_ID);
      this.props.annotations.forEach(this.display_annotation);
      scrollToLine(this.props.focusLine);
    }
  }

  componentDidUpdate() {
    if (this.props.content) {
      this.ready_annotations(RAW_TEXT_DIV_ID);
      this.props.annotations.forEach(this.display_annotation);
      scrollToLine(this.props.focusLine);
    }
  }

  // Generate text view with syntax highlighting and annotations.
  ready_annotations = (source_id) => {
    // Remove existing syntax highlighted code.
    $('.dp-highlighter').remove();
    dp.SyntaxHighlighter.HighlightAll(source_id);
    window.syntax_highlighter_adapter = new SyntaxHighlighter1p5Adapter($('.dp-highlighter ol')[0]);

    // Apply modifications to Syntax Highlighter
    window.syntax_highlighter_adapter.applyMods();

    if (this.props.resultView) {
      window.annotation_type = ANNOTATION_TYPES.CODE;

      window.annotation_manager = new SourceCodeLineAnnotations(
        new SourceCodeLineManager(
          window.syntax_highlighter_adapter,
          new SourceCodeLineFactory(),
          new SourceCodeLineArray()),
        new AnnotationTextManager(),
        new AnnotationTextDisplayer());
    }
  };

  display_annotation = (annotation) => {
    let content = '';
    if (!annotation.deduction) {
      content += annotation.content;
    } else {
      content += annotation.content + ' [' + annotation.criterion_name + ': -' + annotation.deduction + ']';
    }
    add_annotation_text(annotation.annotation_text_id, content);
    annotation_manager.annotateRange(
      annotation.id,
      {
        start: annotation.line_start,
        end: annotation.line_end,
        column_start: annotation.column_start,
        column_end: annotation.column_end
      },
      annotation.annotation_text_id
    );
  };

  componentWillUnmount() {
    $('.dp-highlighter').remove();
  }

  render() {
    return (
      <pre id={RAW_TEXT_DIV_ID} name={RAW_TEXT_DIV_ID} className={this.props.type}>
        {this.props.content}
      </pre>
    );
  }
}


// Scroll to display the given line.
function scrollToLine(lineNumber) {
  if (lineNumber === undefined || lineNumber === null) {
    return;
  }

  const line = $(syntax_highlighter_adapter.root).find(`li:nth-of-type(${lineNumber})`)[0];
  if (line) {
    line.scrollIntoView();
  }
}
