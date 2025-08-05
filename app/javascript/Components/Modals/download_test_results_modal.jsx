import React from "react";
import Modal from "react-modal";

class DownloadTestResultsModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      studentRun: true,
      instructorRun: false,
      latest: true,
      format: "json",
    };
  }

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

        <div className="feature-grid-wrap">
          <fieldset>
            <legend>{I18n.t("activerecord.attributes.test_run.user")}</legend>
            <div className="feature-row">
              <div className="feature-option">
                <input
                  type="radio"
                  id="run-by-anyone"
                  value="anyone"
                  checked={this.state.studentRun && this.state.instructorRun}
                  onChange={() => this.setState({studentRun: true, instructorRun: true})}
                />
                <label htmlFor="run-by-anyone">{I18n.t("anyone")}</label>
              </div>
              <div className="feature-option">
                <input
                  type="radio"
                  id="run-by-student"
                  value="student"
                  checked={this.state.studentRun && !this.state.instructorRun}
                  onChange={() => this.setState({studentRun: true, instructorRun: false})}
                />
                <label htmlFor="run-by-student">{I18n.t("activerecord.models.student.one")}</label>
              </div>
              <div className="feature-option">
                <input
                  type="radio"
                  id="run-by-instructor"
                  value="instructor"
                  checked={!this.state.studentRun && this.state.instructorRun}
                  onChange={() => this.setState({studentRun: false, instructorRun: true})}
                />
                <label htmlFor="run-by-instructor">
                  {I18n.t("activerecord.models.instructor.one")}
                </label>
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>{I18n.t("activerecord.attributes.test_run.type")}</legend>
            <div className="feature-row">
              <div className="feature-option">
                <input
                  type="radio"
                  id="type-all"
                  value="all"
                  checked={!this.state.latest}
                  onChange={() => this.setState({latest: false, format: "json"})}
                />
                <label htmlFor="type-all">{I18n.t("all")}</label>
              </div>
              <div className="feature-option">
                <input
                  type="radio"
                  id="type-latest"
                  value="latest"
                  checked={this.state.latest}
                  onChange={() => this.setState({latest: true})}
                />
                <label htmlFor="type-latest">{I18n.t("latest")}</label>
              </div>
            </div>
          </fieldset>

          <fieldset>
            <legend>{I18n.t("file_format")}</legend>
            <div className="feature-row">
              <div className="feature-option">
                <input
                  type="radio"
                  id="format-json"
                  value="json"
                  checked={this.state.format === "json"}
                  onChange={() => this.setState({format: "json"})}
                />
                <label htmlFor="format-json">{I18n.t("format.json")}</label>
              </div>
              <div className="feature-option">
                <input
                  disabled={!this.state.latest}
                  type="radio"
                  id="format-csv"
                  value="csv"
                  checked={this.state.format === "csv"}
                  onChange={() => this.setState({format: "csv"})}
                />
                <label htmlFor="format-csv">{I18n.t("format.csv")}</label>
              </div>
            </div>
          </fieldset>
        </div>

        <div className="feature-submit-group">
          <input
            onClick={this.props.onRequestClose}
            type="reset"
            id="cancel"
            value={I18n.t("cancel")}
          />

          <a
            href={Routes.download_test_results_course_assignment_path({
              course_id: this.props.course_id,
              id: this.props.assignment_id,
              format: this.state.format,
              latest: this.state.latest,
              studentRun: this.state.studentRun,
              instructorRun: this.state.instructorRun,
              _options: true,
            })}
          >
            <button type="submit" name="download-test-results" onClick={this.props.onRequestClose}>
              {I18n.t("download")}
            </button>
          </a>
        </div>
      </Modal>
    );
  }
}

export default DownloadTestResultsModal;
