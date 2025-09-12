import React from "react";
import Modal from "react-modal";

class SubmitUrlUploadModal extends React.Component {
  constructor() {
    super();
    this.state = {
      newUrl: "",
      newUrlText: "",
      manualUrlAlias: false,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.newUrl, this.state.newUrlText);
    this.setState({
      newUrl: "",
      newUrlText: "",
    });
  };

  handleUrlChange = event => {
    const urlInput = event.target.value;
    try {
      if (!this.state.manualUrlAlias) {
        const validatedURL = new URL(urlInput);
        const suggestedText = validatedURL.hostname;
        this.setState({newUrlText: suggestedText});
      }
    } catch (e) {
      // If here, URL object creation failed and URL is invalid. Thus, no recommended text
    } finally {
      this.setState({newUrl: urlInput});
    }
  };

  handleUrlAliasChange = event => {
    this.setState({newUrlText: event.target.value, manualUrlAlias: true});
  };

  handleModalClose = () => {
    this.setState({
      newUrl: "",
      newUrlText: "",
      manualUrlAlias: false,
    });
    this.props.onRequestClose();
  };

  render() {
    return (
      <Modal
        className="react-modal"
        isOpen={this.props.isOpen}
        onRequestClose={this.handleModalClose}
      >
        <h2>{I18n.t("submit_the", {item: I18n.t("submissions.student.link")})}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>
              <div className={"modal-inline-label"}>
                <label className={"required"}>{I18n.t("submissions.student.url")}</label>
              </div>
              <input
                type={"url"}
                name={"new_url"}
                value={this.state.newUrl}
                onChange={this.handleUrlChange}
                required={true}
              />
            </div>
            <div className={"modal-container"}>
              <div className={"modal-inline-label"}>
                <label className={"required"}>{I18n.t("submissions.student.url_text")}</label>
              </div>
              <input
                type={"text"}
                name={"new_url_text"}
                value={this.state.newUrlText}
                onChange={this.handleUrlAliasChange}
                required={true}
                className={"required"}
              />
            </div>
          </div>
          <div className={"modal-container"}>
            <input type="submit" value={I18n.t("save")} />
          </div>
        </form>
      </Modal>
    );
  }
}

export default SubmitUrlUploadModal;
