import React from 'react';
import {render} from 'react-dom';


class TextViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      content: '',
      type: '',
      focus_line: undefined
    };
  }

  componentDidMount() {
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.content) {
      // Remove existing syntax highlighted code.
      $('.dp-highlighter').remove();

      dp.SyntaxHighlighter.HighlightAll('code');

      source_code_ready();
      // Apply modifications to Syntax Highlighter
      syntax_highlighter_adapter.applyMods();

      annotationTable.display_annotations(this.state.submission_file_id);

      if (this.state.focus_line !== undefined) {
        focus_source_code_line(this.state.focus_line);
      }
    }
  }

  /*
   * Update the contents being displayed with the given submission file id.
   */
  set_submission_file = (submission_file_id, focus_line) => {
    // Clear out any annotation_texts still on the screen
    // TODO: (Is this really necessary?)
    $('.annotation_text_display').each(function() {
      this.remove();
    });

    fetch(Routes.get_file_assignment_submission_path(
      '',
      this.props.assignment_id,
      this.props.submission_id,
      {submission_file_id: submission_file_id}),
      {
        credentials: 'include',
        headers: {'Content-Type': 'text/plain'}
      })
      .then(res => res.json())
      .then(body => this.setState({
        submission_file_id: submission_file_id,
        content: JSON.parse(body.content),
        type: body.type,
        // TODO: use this by calling focus_source_code_line
        focus_line: focus_line
      }));
  };

  render() {
    return (
      <pre id="code" name="code" className={this.state.type}>
        {this.state.content}
      </pre>
    );
  }
}


export function makeTextViewer(elem, props) {
  return render(<TextViewer {...props}/>, elem);
}
