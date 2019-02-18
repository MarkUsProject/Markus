import React from 'react'
import { render } from 'react-dom'
import FileManager from './markus_file_manager'


class AutotestFileManager extends React.Component {

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
    fetch(Routes.populate_file_manager_assignment_automated_tests_path(this.props.assignment_id))
      .then(data => data.json())
      .then(data => this.setState({files: data}));
  };

  handleCreateFiles = (files, prefix) => {
  };

  handleDeleteFile = (fileKey) => {
  };

  render() {
    return (
      <FileManager
        files={this.state.files}
        noFilesMessage={I18n.t('submissions.no_files_available')}
        readOnly={false}
        onDeleteFile={this.handleDeleteFile}
        onCreateFiles={this.handleCreateFiles}
      />
    );
  }
}

export function makeAutotestFileManager(elem, props) {
  render(<AutotestFileManager {...props} />, elem);
}
