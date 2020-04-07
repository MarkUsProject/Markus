import React from 'react'
import { render } from 'react-dom'
import FileManager from './markus_file_manager'
import StarterCodeFileUploadModal from './Modals/starter_code_file_upload_modal'


class StarterCodeFileManager extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      files: [],
      showModal: false,
      uploadTarget: undefined
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.populate_file_manager_assignment_path(this.props.assignment_id))
      .then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  handleCreateFiles = (files, overwrite) => {
    const prefix = this.state.uploadTarget || '';
    this.setState({showModal: false, uploadTarget: undefined});
    let data = new FormData();
    Array.from(files).forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', '/' + prefix); // Server expects path with leading slash (TODO: fix that)
    if (this.props.grouping_id) {
      data.append('grouping_id', this.props.grouping_id);
    }
    data.append('overwrite', overwrite);
    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
      data: data,
      processData: false,  // tell jQuery not to process the data
      contentType: false   // tell jQuery not to set contentType
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData);
  };

  handleDeleteFile = (fileKeys) => {
    if (!this.state.files.some(f => fileKeys.includes(f.key))) {
      return;
    }

    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
      data: {
        delete_files: fileKeys,
      }
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleCreateFolder = (folderKey) => {
    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
      data: {
        new_folders: [folderKey],
        grouping_id: this.props.grouping_id
      }
    }).then(typeof this.props.onChange === 'function' ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleDeleteFolder = (folderKey) => {
    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
      data: {
        delete_folders: [folderKey],
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

  openUploadModal = (uploadTarget) => {
    this.setState({showModal: true, uploadTarget: uploadTarget})
  };

  getDownloadAllURL = () => {
    // TODO: implement this route in assignments_controller.rb.
    return '';
  };

  render() {
    return (
      <div>
        <p>{I18n.t('assignments.starter_code.description')}</p>
        <FileManager
          files={this.state.files}
          noFilesMessage={I18n.t('submissions.no_files_available')}

          readOnly={false}
          onDeleteFile={this.handleDeleteFile}
          onCreateFiles={this.handleCreateFiles}
          onCreateFolder={this.props.readOnly ? undefined : this.handleCreateFolder}
          onRenameFolder={!this.props.readOnly && typeof this.handleCreateFolder === 'function' ? () => {} : undefined}
          onDeleteFolder={this.props.readOnly ? undefined : this.handleDeleteFolder}
          downloadAllURL={this.getDownloadAllURL()}
          onActionBarAddFileClick={this.props.readOnly ? undefined : this.openUploadModal}
          disableActions={{rename: true}}
        />
        <StarterCodeFileUploadModal
          isOpen={this.state.showModal}
          onRequestClose={() => this.setState({showModal: false, uploadTarget: undefined})}
          onSubmit={this.handleCreateFiles}
        />
      </div>
    );
  }
}

StarterCodeFileManager.defaultProps = {
  groupsExist: false,
};


export function makeStarterCodeFileManager(elem, props) {
  render(<StarterCodeFileManager {...props} />, elem);
}
