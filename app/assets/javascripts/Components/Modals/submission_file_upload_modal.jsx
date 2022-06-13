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
    if (this.state.newFiles.length == 1) {
      this.props.onSubmit(this.state.newFiles, this.state.unzip, this.state.single_file_name);
    } else {
      this.props.onSubmit(this.state.newFiles, this.state.unzip);
    }
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

  render() {
    let fileInput;
    if (this.state.newFiles.length == 1) {
      if (this.props.onlyRequiredFiles) {
        fileInput = (
          <select onChange={this.handleNameChange} value={this.state.single_file_name}>
            <option key={"select_file"}>Please Select File Name</option>
            {this.props.requiredFiles.map(file => {
              return (
                <option key={file.filename} value={file.filename}>
                  {file.filename}
                </option>
              );
            })}
          </select>
        );
      } else if (this.props.requiredFiles.length >= 1) {
        fileInput = (
          <input
            list="fileInput_datalist"
            onChange={this.handleNameChange}
            placeholder={"Change File Name"}
          ></input>
        );
      } else {
        fileInput = (
          <input
            value={this.state.single_file_name}
            type={"text"}
            name={"filename"}
            onChange={this.handleNameChange}
          />
        );
      }
    } else {
      fileInput = <div></div>;
    }

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
            {this.state.newFiles.length == 1 ? (
              <div>
                <datalist id="fileInput_datalist">
                  {this.props.requiredFiles.map(file => {
                    return <option key={file.filename} value={file.filename}></option>;
                  })}
                </datalist>

                {fileInput}
              </div>
            ) : (
              <div></div>
            )}
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
