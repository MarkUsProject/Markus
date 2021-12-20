import React from "react";
import Modal from "react-modal";

class SubmitUrlUploadModal extends React.Component {
  state = {
    newUrl: "https://www.youtube.com/embed/dQw4w9WgXcQ"
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.newUrl);
  };

  handleUrlSubmit = event => {
    this.setState({newUrl: "https://www.youtube.com/embed/dQw4w9WgXcQ"});
  };

  render() {
    const { isOpen, onRequestClose } = this.props
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
                type={"url"}
                name={"new_url"}
                onChange={this.handleUrlSubmit}
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
