import React from 'react';


export class FeedbackFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: props.feedbackFiles ? props.feedbackFiles[0].id : null,
      fileContents: null,
      fileType: null,
    }
  }

  componentDidMount() {
    if (this.state.selectedFile !== null) {
      this.fetchFeedbackFile();
    }
  }

  fetchFeedbackFile = () => {
    $.get({
      url: Routes.get_feedback_file_assignment_submission_path(
        this.props.assignment_id, this.props.submission_id),
      data: {feedback_file_id: this.state.selectedFile}
    }).then((data, status, request) => {
      this.setState({
        fileContents: data,
        fileType: request.getResponseHeader('Content-Type'),
      });
    });
  };

  updateSelectedFile = (event) => {
    this.setState({selectedFile: event.target.value}, this.fetchFeedbackFile);
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

    let fileContents;
    if (this.state.fileContents === null) {
      fileContents = '';
    } else if (this.state.fileType.startsWith('text')) {
      fileContents = <pre>{this.state.fileContents}</pre>;
    } else if (this.state.fileType.startsWith('image')) {
      fileContents =
        <img
          src={`data:'${this.state.fileType};base64,${this.state.fileContents}'`}
          style={{maxWidth: '70%'}}
        />;
    } else {
      fileContents = '';
    }

    return (
      <div>
        <div className='react-tabs-panel-action-bar'>
          <div>
            {feedbackSelector}
          </div>
        </div>
        <div id='feedback_file_content'>
          {fileContents}
        </div>
      </div>
    );
  }
}
