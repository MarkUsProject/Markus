import React from "react";
import Modal from "react-modal";

class CollectSubmissionsModal extends React.Component {
  static defaultProps = {
    override: false,
  };

  constructor(props) {
    super(props);
    this.state = {
      override: this.props.override,
      collect_time: this.props.isScannedExam ? "collect_current" : "collect_due_date",
      apply_late_penalty: !this.props.isScannedExam,
      retain_existing_grading: true,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(
      this.state.override,
      this.state.collect_time === "collect_current",
      // Always apply late penalty when collecting based on due date
      this.state.apply_late_penalty || this.state.collect_time === "collect_due_date",
      this.state.override && this.state.retain_existing_grading
    );
  };

  handleOverrideChange = event => {
    this.setState({override: event.target.checked});
  };

  handleRetainExistingGradingChange = event => {
    this.setState({retain_existing_grading: event.target.checked});
  };

  handleCollectTimeChange = event => {
    this.setState({collect_time: event.target.value});
  };

  handleApplyLatePenaltyChange = event => {
    this.setState({apply_late_penalty: event.target.checked});
  };

  warningText = () => {
    let label_text = I18n.t("submissions.collect.results_loss_warning");
    if (this.props.isScannedExam) {
      label_text = label_text.concat(
        " ",
        I18n.t("submissions.collect.scanned_exam_latest_warning")
      );
    }
    return label_text;
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("submissions.collect.submit")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <p>{this.warningText()}</p>
            {!this.props.isScannedExam && (
              <fieldset>
                <legend>{I18n.t("submissions.collect.collection_time")}</legend>
                <p>
                  <label htmlFor={"collect_due_date"}>
                    <input
                      type={"radio"}
                      name={"collect_time"}
                      value={"collect_due_date"}
                      checked={this.state.collect_time === "collect_due_date"}
                      onChange={this.handleCollectTimeChange}
                    />
                    {I18n.t("submissions.collect.collect_due_date")}
                  </label>
                </p>
                <p>
                  <label htmlFor={"collect_current"}>
                    <input
                      type={"radio"}
                      name={"collect_time"}
                      value={"collect_current"}
                      checked={this.state.collect_time === "collect_current"}
                      onChange={this.handleCollectTimeChange}
                    />
                    {I18n.t("submissions.collect.collect_current")}
                  </label>
                </p>
              </fieldset>
            )}
            <fieldset>
              <legend>{I18n.t("submissions.collect.collection_options")}</legend>
              <p>
                <label>
                  <input
                    type="checkbox"
                    defaultChecked={this.state.override}
                    name="override"
                    data-testid="chk_recollect_existing_submissions"
                    onChange={this.handleOverrideChange}
                  />
                  &nbsp;
                  <span data-testid="lbl_recollect_existing_submissions">
                    {I18n.t("submissions.collect.override_existing")}
                  </span>
                </label>
              </p>
              {this.state.override && (
                <p style={{marginLeft: "15px"}}>
                  <input
                    type="checkbox"
                    defaultChecked={this.state.retain_existing_grading}
                    name="retain_existing_grading"
                    id="retain_existing_grading"
                    data-testid="chk_retain_existing_grading"
                    onChange={this.handleRetainExistingGradingChange}
                  />
                  &nbsp;
                  <label
                    htmlFor="retain_existing_grading"
                    data-testid="lbl_retain_existing_grading"
                  >
                    {I18n.t("submissions.collect.retain_existing_grading")}
                  </label>
                  {!this.state.retain_existing_grading && (
                    <div
                      data-testid="div_grading_data_will_be_lost"
                      className="warning"
                      style={{marginTop: "4px"}}
                    >
                      {I18n.t("submissions.collect.grading_data_will_be_lost")}
                    </div>
                  )}
                </p>
              )}
              {this.state.collect_time === "collect_current" && !this.props.isScannedExam && (
                <p>
                  <label>
                    <input
                      type="checkbox"
                      defaultChecked={this.state.apply_late_penalty}
                      name="apply_late_penalty"
                      onChange={this.handleApplyLatePenaltyChange}
                    />
                  </label>
                  &nbsp;
                  <span>{I18n.t("submissions.collect.apply_late_penalty")}</span>
                </p>
              )}
            </fieldset>
            <section className={"modal-container dialog-actions"}>
              <input
                type="submit"
                data-testid="btn_collect_submissions"
                value={I18n.t("submissions.collect.submit")}
              />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}

export default CollectSubmissionsModal;
