import React from 'react';
import {FileViewer} from './file_viewer';
import {lookup} from "mime-types";


export class FeedbackFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: props.feedbackFiles ? props.feedbackFiles[0].id : null
    }
  }

  updateSelectedFile = (event) => {
    this.setState({selectedFile: parseInt(event.target.value, 10)});
  };

  render() {
    let feedbackSelector;
    if (this.props.feedbackFiles) {
      feedbackSelector =
        <select
          onChange={this.updateSelectedFile}
          value={this.state.selectedFile}
          className={'dropdown'}
        >
          {this.props.feedbackFiles.map(file =>
            <option value={file.id} key={file.id}>{file.filename}</option>
          )}
        </select>;
    } else {
      feedbackSelector =
        <select
          onChange={this.updateSelectedFile}
          className={'dropdown'}
        >
          <option value=''>{I18n.t('results.no_feedback_files')}</option>
        </select>;
    }

    let url, file_obj;
    if (this.state.selectedFile !== null) {
      url = Routes.get_feedback_file_assignment_submission_path(
        '',
        this.props.assignment_id,
        this.props.submission_id,
        {feedback_file_id: this.state.selectedFile}
      );
      file_obj = this.props.feedbackFiles.find(file => file.id === this.state.selectedFile);
    }

    return (
        [<div className='react-tabs-panel-action-bar' key={'feedback-file-actionbar'}>
          <div>
            {feedbackSelector}
          </div>
        </div>,
        <div id='feedback_file_content' key={'feedback-file-view'}>
          <FileViewer
            assignment_id={this.props.assignment_id}
            submission_id={this.props.submission_id}
            selectedFile={file_obj.filename}
            selectedFileURL={url}
            mime_type={lookup(file_obj.filename)}
            selectedFileType={file_obj.type}
          />
        </div>]
    );
  }
}
