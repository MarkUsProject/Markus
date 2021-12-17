import React from "react";
import Modal from "react-modal";

class SubmitUrlUploadModal extends React.Component {

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    //this.props.onSubmit(this.state.newFiles, this.state.unzip);
  };

  handleFileUpload = event => {
    //this.setState({newFiles: event.target.files});
  };

  toggleUnzip = () => {
    //this.setState({unzip: !this.state.unzip});
  };

  render() {
    const [isOpen, onRequestClose] = this.props
    return (
      <Modal
        className="react-modal"
        isOpen={isOpen}
        onRequestClose={onRequestClose}
      >
        <h2>{I18n.t("submit_link")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>
              <input
                type={"file"}
                name={"new_files"}
                multiple={true}
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

export default SubmitUrlUploadModal;
