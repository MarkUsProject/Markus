import React from "react";
import Modal from "react-modal";

class SubmissionFileUploadModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      newFiles: [],
      unzip: false,
      renameTo: "",
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.newFiles, undefined, this.state.unzip, this.state.renameTo);
  };

  handleFileUpload = event => {
    this.setState({newFiles: event.target.files});
  };

  toggleUnzip = () => {
    this.setState({unzip: !this.state.unzip});
  };

  handleRenameChange = event => {
    this.setState({renameTo: event.target.value});
  };

  fileRenameInputBox = () => {
    let fileRenameInput;
    let filesToShow;
    if (this.props.uploadTarget) {
      let filenames = this.props.requiredFiles.filter(
        filename =>
          filename.startsWith(this.props.uploadTarget) &&
          !filename.includes("/", this.props.uploadTarget.length)
      );
      filesToShow = filenames.map(filename => filename.slice(this.props.uploadTarget.length));
    } else {
      filesToShow = this.props.requiredFiles.filter(filename => !filename.includes("/"));
    }
    if (this.props.onlyRequiredFiles) {
      fileRenameInput = (
        <select
          className={"select-filename"}
          onChange={this.handleRenameChange}
          value={this.state.renameTo}
          disabled={this.state.newFiles.length !== 1}
          title={I18n.t("submissions.student.one_file_allowed")}
          id={"rename-box"}
        >
          <option key={"select_file"}>{I18n.t("select_filename")}</option>
          {filesToShow.map(filename => {
            return (
              <option key={filename} value={filename}>
                {filename}
              </option>
            );
          })}
        </select>
      );
    } else if (this.props.requiredFiles.length >= 1) {
      fileRenameInput = [
        <datalist id="fileInput_datalist">
          {filesToShow.map(filename => {
            return <option key={filename} value={filename}></option>;
          })}
        </datalist>,
        <input
          className={"datalist-textbox"}
          list="fileInput_datalist"
          onChange={this.handleRenameChange}
          placeholder={I18n.t("select_filename")}
          value={this.state.renameTo}
          disabled={this.state.newFiles.length !== 1}
          title={I18n.t("submissions.student.one_file_allowed")}
          id={"rename-box"}
        />,
      ];
    } else {
      fileRenameInput = (
        <input
          className={"file-rename-textbox"}
          value={this.state.renameTo}
          type={"text"}
          name={"filename"}
          onChange={this.handleRenameChange}
          disabled={this.state.newFiles.length !== 1}
          title={I18n.t("submissions.student.one_file_allowed")}
          id={"rename-box"}
        />
      );
    }
    return fileRenameInput;
  };

  clearState = () => {
    this.setState({newFiles: [], renameTo: ""});
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        onAfterClose={this.clearState}
      >
        <h2>{I18n.t("upload")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div>
              <label htmlFor="unzip">
                <input
                  type={"checkbox"}
                  id={"unzip"}
                  name={"unzip"}
                  checked={this.state.unzip}
                  onChange={this.toggleUnzip}
                />{" "}
                {I18n.t("modals.file_upload.unzip")}
              </label>
            </div>
            <div className={"modal-container"}>
              <input
                type={"file"}
                name={"new_files"}
                multiple={true}
                onChange={this.handleFileUpload}
              />
            </div>
            <label htmlFor={"rename-box"}>
              {I18n.t("submissions.student.rename_file_to")}&nbsp;
              {this.fileRenameInputBox()}
            </label>
            <div className={"modal-container"}>
              <input
                type="submit"
                value={I18n.t("save")}
                disabled={this.state.newFiles.length === 0}
              />
            </div>
          </div>
        </form>
      </Modal>
    );
  }
}

export default SubmissionFileUploadModal;
