import React from "react";
import Modal from "react-modal";

class DownloadTestResultsModal extends React.Component {
  componentDidMount() {
    Modal.setAppElement("body");
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>
          {I18n.t("download_the", {
            item: I18n.t("activerecord.models.test_result.other"),
          })}
        </h2>
        <div className={"modal-container-vertical"} style={{alignItems: "center"}}>
          <a
            href={Routes.download_test_results_course_assignment_path({
              course_id: this.props.course_id,
              id: this.props.assignment_id,
              format: "json",
              _options: true,
            })}
          >
            <button
              type="submit"
              name="download-test-results-json"
              onClick={this.props.onRequestClose}
            >
              <i className="fa-solid fa-download" aria-hidden="true" />
              {I18n.t("download_json")}
            </button>
          </a>
          <a
            href={Routes.download_test_results_course_assignment_path({
              course_id: this.props.course_id,
              id: this.props.assignment_id,
              format: "csv",
              _options: true,
            })}
          >
            <button
              type="submit"
              name="download-test-results-csv"
              onClick={this.props.onRequestClose}
            >
              <i className="fa-solid fa-download" aria-hidden="true" />
              {I18n.t("download_csv")}
            </button>
          </a>
          <a
            href={Routes.download_test_results_course_assignment_path({
              course_id: this.props.course_id,
              id: this.props.assignment_id,
              format: "zip",
              _options: true,
            })}
          >
            <button
              type="submit"
              name="download-test-results-zip"
              onClick={this.props.onRequestClose}
            >
              <i className="fa-solid fa-download" aria-hidden="true" />
              {I18n.t("download_zip")}
            </button>
          </a>
          <section className="dialog-actions">
            <input
              onClick={this.props.onRequestClose}
              type="reset"
              id="cancel"
              value={I18n.t("cancel")}
            />
          </section>
        </div>
      </Modal>
    );
  }
}

export default DownloadTestResultsModal;
