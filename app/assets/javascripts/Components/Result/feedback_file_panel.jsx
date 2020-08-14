import React from 'react';
import {FileViewer} from './file_viewer'


export class FeedbackFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: props.feedbackFiles ? props.feedbackFiles[0].id : null
    }
  }

  updateSelectedFile = (event) => {
    this.setState({selectedFile: event.target.value});
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
            feedbackFile={this.state.selectedFile}
          />
        </div>]
    );
  }
}
