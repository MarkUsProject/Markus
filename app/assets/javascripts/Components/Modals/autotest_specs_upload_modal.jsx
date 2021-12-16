import React from "react";
import Modal from "react-modal";

class AutotestSpecsUploadModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      newFile: null,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    if (!!this.state.newFile) {
      this.props.onSubmit(this.state.newFile);
      this.setState({newFile: null});
    } else {
      this.props.onRequestClose();
    }
  };

  handleFileUpload = event => {
    this.setState({newFile: event.target.files[0] || null});
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("upload")}</h2>
        <div>
          <p>{I18n.t("automated_tests.specs_file_upload_message")}</p>
        </div>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>
              <input
                type={"file"}
                name={"new_files"}
                multiple={false}
                onChange={this.handleFileUpload}
              />
            </div>
            <div className={"modal-container"}>
              <input type="submit" value={I18n.t("save")} />
            </div>
          </div>
        </form>
      </Modal>
    );
  }
}

export default AutotestSpecsUploadModal;
