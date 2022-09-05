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
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.override);
  };

  handleOverrideChange = event => {
    this.setState({override: event.target.checked});
  };

  warningText = () => {
    let label_text = I18n.t("submissions.collect.results_loss_warning");
    if (this.props.isScannedExam) {
      label_text = label_text.concat(
        " ",
        I18n.t("submissions.collect.scanned_exam_latest_warning"),
      );
    }
    return label_text;
  };

  render() {
    return (
      <Modal
        className="react-modal dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <h2>{I18n.t("submissions.collect.submit")}</h2>
        <form onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <p>{this.warningText()}</p>
            <p>
              <label>
                <input type="checkbox" name="override" onChange={this.handleOverrideChange} />
                &nbsp;
                <span
                  dangerouslySetInnerHTML={{
                    __html: I18n.t("submissions.collect.override_existing_html"),
                  }}
                />
              </label>
            </p>
            <section className={"modal-container dialog-actions"}>
              <input type="submit" value={I18n.t("submissions.collect.submit")} />
            </section>
          </div>
        </form>
      </Modal>
    );
  }
}

export default CollectSubmissionsModal;
