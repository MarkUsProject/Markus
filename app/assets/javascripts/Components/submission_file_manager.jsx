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

  static defaultProps = {
    fetchOnMount: true,
    readOnly: false,
    revision_identifier: undefined
  };

  componentDidMount() {
    window.modal_addnew = new ModalMarkus('#addnew_dialog');
    if (this.props.fetchOnMount) {
      this.fetchData();
    }
  }

  fetchData = () => {
    let data = {assignment_id: this.props.assignment_id};
    if (typeof this.props.grouping_id !== 'undefined') {
      data.grouping_id = this.props.grouping_id;
    }
    if (typeof this.props.revision_identifier !== 'undefined') {
      data.revision_identifier = this.props.revision_identifier;
    }

    fetch(
      Routes.populate_file_manager_assignment_submissions_path(data), {
      credentials: 'same-origin',
      headers: {
        'content-type': 'application/json'
      }
    }).then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  // Update state when a new revision_identifier props is passed
  componentDidUpdate(oldProps) {
    if (oldProps.revision_identifier !== this.props.revision_identifier) {
      this.fetchData();
    }
  }

  handleCreateFiles = (files, prefix) => {
    let data = new FormData();
    files.forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', '/' + prefix); // Server expects path with leading slash (TODO: fix that)
    if (this.props.grouping_id) {
      data.append('grouping_id', this.props.grouping_id);
    }
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: data,
      processData: false,  // tell jQuery not to process the data
      contentType: false   // tell jQuery not to set contentType
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData);
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
    file_revisions[file.key] = this.props.revision_identifier;
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: {
        delete_files: [file.key],
        file_revisions: file_revisions,
        grouping_id: this.props.grouping_id
      }
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleCreateFolder = (folderKey) => {
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: {
        new_folders: [folderKey],
        grouping_id: this.props.grouping_id
      }
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleDeleteFolder = (folderKey) => {
    let folder_revisions = {};
    folder_revisions[folderKey] = this.props.revision_identifier
    $.post({
      url: Routes.update_files_assignment_submissions_path(this.props.assignment_id),
      data: {
        delete_folders: [folderKey],
        folder_revisions: folder_revisions,
        grouping_id: this.props.grouping_id
      }
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleActionBarDeleteClick = (event) => {
    event.preventDefault();
    if (this.state.selection) {
      this.handleDeleteFile(this.state.selection);
    }
  };

  getDownloadAllURL = () => {
    return Routes.downloads_assignment_submission_path('', this.props.assignment_id, this.props.grouping_id, {
      revision_identifier: this.props.revision_identifier,
      grouping_id: this.props.grouping_id,
    });
  };

  render() {
    return (
      <FileManager
        files={this.state.files}
        noFilesMessage={I18n.t('submissions.no_files_available')}

        readOnly={this.props.readOnly}
        onDeleteFile={this.props.readOnly ? undefined : this.handleDeleteFile}
        onCreateFiles={this.props.readOnly ? undefined : this.handleCreateFiles}
        onCreateFolder={this.props.readOnly ? undefined : this.handleCreateFolder}
        onRenameFolder={() => {}}
        onDeleteFolder={this.props.readOnly ? undefined : this.handleDeleteFolder}
        downloadAllURL={this.getDownloadAllURL()}
      />
    );
  }
}

export function makeSubmissionFileManager(elem, props) {
  render(<SubmissionFileManager {...props} />, elem);
}

export { SubmissionFileManager };
