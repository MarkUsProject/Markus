import React from 'react';
import {render} from 'react-dom';


export class TextViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidMount() {
    if (this.props.content) {
      // Remove existing syntax highlighted code.
      $('.dp-highlighter').remove();

      dp.SyntaxHighlighter.HighlightAll('code');

      source_code_ready();
      // Apply modifications to Syntax Highlighter
      syntax_highlighter_adapter.applyMods();

      annotationPanel.annotationTable.current.display_annotations(this.props.submission_file_id);

      if (this.props.focus_line !== undefined) {
        focus_source_code_line(this.props.focus_line);
      }
    }
  }

  componentDidUpdate() {
    if (this.props.content) {
      dp.SyntaxHighlighter.HighlightAll('code');

      source_code_ready();
      // Apply modifications to Syntax Highlighter
      syntax_highlighter_adapter.applyMods();

      annotationPanel.annotationTable.current.display_annotations(this.props.submission_file_id);

      if (this.props.focus_line !== undefined) {
        focus_source_code_line(this.props.focus_line);
      }
    }
  }

  render() {
    return (
      <pre id="code" name="code" className={this.props.type}>
        {this.props.content}
      </pre>
    );
  }
}
