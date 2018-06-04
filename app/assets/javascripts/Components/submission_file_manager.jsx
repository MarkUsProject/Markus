import React from 'react'
import { render } from 'react-dom'
import FileManager from './markus_file_manager'


class SubmissionFileManager extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      files: []
    };
  }

  componentDidMount() {
    window.modal_addnew = new ModalMarkus('#addnew_dialog');
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.populate_file_manager_assignment_submissions_path(this.props.assignment_id), {
      credentials: 'same-origin',
      headers: {
        'content-type': 'application/json'
      }
    }).then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  handleCreateFiles = (files, prefix) => {
    let data = new FormData();
    files.forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', '/' + prefix); // Server expects path with leading slash (TODO: fix that)
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: data,
      processData: false,  // tell jQuery not to process the data
      contentType: false   // tell jQuery not to set contentType
    }).then(this.fetchData);
  };

  handleDeleteFile = (fileKey) => {
    let deleteFiles = [];
    this.state.files.map((file) => {
      if (file.key === fileKey) {
        deleteFiles.push(file)
      }
    });
    if (!deleteFiles) {
      return;
    }

    let file = deleteFiles[0];
    let file_revisions = {};
    file_revisions[file.key] = file.last_modified_revision;
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: {
        delete_files: [file.key],
        file_revisions: file_revisions
      }
    }).then(this.fetchData)
      .then(this.endAction);
  };

  handleActionBarDeleteClick = (event) => {
    event.preventDefault();
    if (this.state.selection) {
      this.handleDeleteFile(this.state.selection);
    }
  };

  render() {
    return (
      <FileManager
        files={this.state.files}

        readOnly={this.props.readOnly}
        onDeleteFile={this.props.readOnly ? undefined : this.handleDeleteFile}
        onCreateFiles={this.props.readOnly ? undefined : this.handleCreateFiles}
      />
    );
  }
}

SubmissionFileManager.defaultProps = {
  readOnly: false
};


export function makeSubmissionFileManager(elem, props) {
  render(<SubmissionFileManager {...props} />, elem);
}
