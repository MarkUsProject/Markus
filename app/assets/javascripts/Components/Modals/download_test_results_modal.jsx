import React from "react";
import Modal from "react-modal";

class DownloadTestResultsModal extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
  };

  render() {
    return (
      <Modal
        className="react-modal dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("download_tests")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <button onClick={() => console.log("test json")}>
              <i className="fa fa-download-file-o" aria-hidden="true" />
              &nbsp;{I18n.t("download_json")}
            </button>
            <button onClick={() => console.log("test csv")}>
              <i className="fa fa-download-file-o" aria-hidden="true" />
              &nbsp;{I18n.t("download_csv")}
            </button>
            {/* <%= link_to '',
                { action: 'download',
                  format: 'csv' },
                class: 'make_div_clickable' %> */}
            {/* <div class='clickable_links'>
    <div class='clickable_text'>
      <img class='clickable_image' src='<%= image_path('icons/download-file.png') %>'>
      <%= t(:download_yml) %>
    </div>
    <%= link_to '',
                { action: 'download',
                  format: 'yml' },
                class: 'make_div_clickable' %>
  </div> */}
            <section className="dialog-actions">
              <input
                onClick={this.props.onRequestClose}
                type="reset"
                id="cancel"
                value={I18n.t("cancel")}
              />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}

export default DownloadTestResultsModal;
