import React from "react";
import Modal from "react-modal";

class SubmitUrlUploadModal extends React.Component {
  state = {
    newUrl: "",
    newUrlAlias: "",
  };

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit("https://youtu.be/dQw4w9WgXcQ", "");
  };

  handleUrlChange = event => {
    this.setState({newUrl: event.target.value});
  };

  handleUrlAliasChange = event => {
    this.setState({newUrlAlias: event.target.value});
  };

  render() {
    const {isOpen, onRequestClose} = this.props;
    return (
      <Modal className="react-modal" isOpen={isOpen} onRequestClose={onRequestClose}>
        <h2>{I18n.t("submissions.student.create_link")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <div className={"modal-container"}>
              <label>
                {I18n.t("submissions.student.url")}
                <br />
                <input
                  type={"url"}
                  name={"new_url"}
                  value={this.state.newUrl}
                  onChange={this.handleUrlChange}
                  required={true}
                />
              </label>
            </div>
            <div className={"modal-container"}>
              <label>
                {I18n.t("submissions.student.url_alias")}
                <br />
                <input
                  type={"text"}
                  name={"new_url_alias"}
                  value={this.state.newUrlAlias}
                  onChange={this.handleUrlAliasChange}
                />
              </label>
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
