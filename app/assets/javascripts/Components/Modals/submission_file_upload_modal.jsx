import React from "react";
import Modal from "react-modal";

class SubmissionFileUploadModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      newFiles: [],
      unzip: false,
      single_file_name: "",
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.newFiles, this.state.unzip, this.state.single_file_name);
  };

  handleFileUpload = event => {
    this.setState({newFiles: event.target.files, single_file_name: event.target.files[0].name});
  };

  toggleUnzip = () => {
    this.setState({unzip: !this.state.unzip});
  };

  handleNameChange = event => {
    this.setState({single_file_name: event.target.value});
  };

  fileRenameInputBox = () => {
    let fileRenameInput;
    let filesToShow;
    if (this.props.uploadTarget) {
      let filenames = this.props.requiredFiles.filter(
        filename =>
          filename.indexOf(this.props.uploadTarget) === 0 &&
          filename
            .slice(filename.indexOf(this.props.uploadTarget) + this.props.uploadTarget.length)
            .indexOf("/") === -1
      );
      filesToShow = filenames.map(filename => {
        return filename.slice(
          filename.indexOf(this.props.uploadTarget) + this.props.uploadTarget.length
        );
      });
    } else {
      filesToShow = this.props.requiredFiles.filter(filename => filename.indexOf("/") === -1);
    }
    if (this.props.onlyRequiredFiles) {
      fileRenameInput = (
        <select
          className={"select-filename"}
          onChange={this.handleNameChange}
          value={this.state.single_file_name}
          disabled={this.state.newFiles.length !== 1}
          title={I18n.t("one_file_allowed")}
        >
          <option key={"select_file"}>{I18n.t("change_filename")}</option>
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
      fileRenameInput = (
        <div>
          <datalist id="fileInput_datalist">
            {filesToShow.map(filename => {
              return <option key={filename} value={filename}></option>;
            })}
          </datalist>
          <input
            className={"datalist-textbox"}
            list="fileInput_datalist"
            onChange={this.handleNameChange}
            placeholder={I18n.t("change_filename")}
            value={this.state.single_file_name}
            disabled={this.state.newFiles.length !== 1}
            title={I18n.t("one_file_allowed")}
          ></input>
        </div>
      );
    } else {
      fileRenameInput = (
        <input
          className={"file-rename-textbox"}
          value={this.state.single_file_name}
          type={"text"}
          name={"filename"}
          onChange={this.handleNameChange}
          disabled={this.state.newFiles.length !== 1}
          title={I18n.t("one_file_allowed")}
        />
      );
    }
    return fileRenameInput;
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
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
            <h3>{I18n.t("file_name")}</h3>
            {this.fileRenameInputBox()}
            <div className={"modal-container"}>
              <input type="submit" value={I18n.t("save")} />
            </div>
          </div>
        </form>
      </Modal>
    );
  }
}

export default SubmissionFileUploadModal;
