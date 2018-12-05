import React from 'react'
import { render } from 'react-dom'
import FileManager from './markus_file_manager'


class StarterCodeFileManager extends React.Component {

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
    fetch(Routes.populate_file_manager_assignment_path(this.props.assignment_id))
      .then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  handleCreateFiles = (files, prefix) => {
    let data = new FormData();
    files.forEach(f => data.append('new_files[]', f, f.name));
    data.append('path', '/' + prefix); // Server expects path with leading slash (TODO: fix that)
    if (this.props.grouping_id) {
      data.append('grouping_id', this.props.grouping_id);
    }
    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
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
    file_revisions[file.key] = file.last_modified_revision;
    $.post({
      url: Routes.upload_starter_code_assignment_path(this.props.assignment_id),
      data: {
        delete_files: [file.key],
        file_revisions: file_revisions,
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
    // TODO: implement this route in assignments_controller.rb.
    return '';
  };

  render() {
    let update = null;
    if (this.props.groupsExist) {
      update =
        <form method="post" action={Routes.update_starter_code_assignment_path(this.props.assignment_id)}>
          <p>{I18n.t('assignment.starter_code.groups_exist')}</p>
          <input type="hidden" name="authenticity_token" value={this.props.authenticity_token} />
          <input id="starter_code_overwrite" type="checkbox" name="overwrite" value="true"/>
          <label for="starter_code_overwrite">{I18n.t('assignment.starter_code.overwrite')}</label>
          <input type="submit" value={I18n.t('assignment.starter_code.update')}/>
        </form>
    }
    return (
      <div>
        <p>{I18n.t('assignment.starter_code.repo_url')}: {this.props.repo_url}</p>
        <p>{I18n.t('assignment.starter_code.description')}</p>

        <FileManager
          files={this.state.files}
          noFilesMessage={I18n.t('student.submission.no_files_available')}

          readOnly={false}
          onDeleteFile={this.handleDeleteFile}
          onCreateFiles={this.handleCreateFiles}
          downloadAllURL={this.getDownloadAllURL()}
        />
        {update}
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
