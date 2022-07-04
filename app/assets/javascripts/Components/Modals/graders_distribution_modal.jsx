import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export class GraderDistributionModal extends React.Component {
  static defaultProps = {
    override: false,
  };

  componentDidMount() {
    this.props.graders.forEach(grader => {
      this.props.setWeighting(grader._id, 1);
    });
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit();
  };

  renderGraderRow = grader => {
    return (
      <div className="flex-row-expand" key={grader.user_name}>
        <label htmlFor={`input-${grader.user_name}`} className="modal-inline-label">
          {grader.user_name}
        </label>
        <input
          id={`input-${grader.user_name}`}
          type="number"
          step="0.01"
          min="0"
          max="100"
          defaultValue="1"
          onChange={event => {
            this.props.setWeighting(grader._id, parseFloat(event.target.value));
          }}
          required={true}
        />
      </div>
    );
  };

  render() {
    return (
      <Modal
        className="react-modal dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <form id="grader-form-random" onSubmit={this.onSubmit}>
          <div className={"modal-container-vertical"}>
            <h2>{I18n.t("graders.weight")}</h2>
            <p className="word-wrap">{I18n.t("graders.random_instruction")}</p>
            <a href="https://github.com/MarkUsProject/Wiki/blob/release/Instructor-Guide--Assignments--Assigning-Graders.md">
              {I18n.t("graders.wiki")}
            </a>
            {this.props.graders.map(grader => this.renderGraderRow(grader))}
          </div>
          <div className={"modal-container"}>
            <input type="submit" value={I18n.t("graders.actions.randomly_assign")} />
          </div>
        </form>
      </Modal>
    );
  }
}

GraderDistributionModal.propTypes = {
  graders: PropTypes.arrayOf(PropTypes.object).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onSubmit: PropTypes.func.isRequired,
  setWeighting: PropTypes.func.isRequired,
};
