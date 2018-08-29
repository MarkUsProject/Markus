import React from 'react';
import {render} from 'react-dom';

import {ImageViewer} from './image_viewer'
import {TextViewer} from './text_viewer'
import {PDFViewer} from './pdf_viewer';


class FileViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      content: '',
      type: '',
      focus_line: undefined,
      url: '',
      submission_file_id: undefined
    };
  }

  /*
   * Update the contents being displayed with the given submission file id.
   */
  set_submission_file = (submission_file_id, focus_line) => {
    if (submission_file_id === this.state.submission_file_id) {
      // TODO: can still scroll to the focus_line here.
      return;
    }

    // Remove existing syntax highlighted code.
    $('.dp-highlighter').remove();

    // TODO: is this the right spot to remove these? Should it be done earlier?
    $('.annotation_text_display').each(function() {
      this.remove();
    });

    fetch(Routes.get_file_assignment_submission_path(
            '',
            this.props.assignment_id,
            this.props.submission_id,
            {submission_file_id: submission_file_id}),
          {credentials: 'include'})
      .then(res => res.json())
      .then(body => {
        if (body.type === 'image' || body.type === 'pdf') {
          this.setState({
            type: body.type,
            submission_file_id: submission_file_id,
            url: Routes.download_assignment_submission_result_path(
              '',
              this.props.assignment_id,
              this.props.submission_id,
              this.props.result_id,
              {
                select_file_id: submission_file_id,
                show_in_browser: true,
                from_codeviewer: true
              }
            )
          });
        } else {
          const content = JSON.parse(body.content).replace(/\r?\n/gm, '\n');
          this.setState({
            submission_file_id: submission_file_id,
            content: content,
            type: body.type,
            // TODO: use this by calling focus_source_code_line
            focus_line: focus_line
          });
        }
      });
  };

  render() {
    if (this.state.type === 'image') {
      return <ImageViewer
        url={this.state.url}
        submission_file_id={this.state.submission_file_id} />;
    } else if(this.state.type === 'pdf') {
      return <PDFViewer
        url={this.state.url}
        submission_file_id={this.state.submission_file_id} />;
    } else {
      return <TextViewer
        type={this.state.type}
        content={this.state.content}
        focus_line={this.state.focus_line}
        submission_file_id={this.state.submission_file_id} />;
    }
  }
}


export function makeFileViewer(elem, props) {
  return render(<FileViewer {...props}/>, elem);
}
