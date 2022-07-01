import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export class GraderDistributionModal extends React.Component {
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
    this.props.graders.forEach(grader => {
      !this.props.weightings[grader._id] ? (this.props.weightings[grader._id] = 1) : null;
    });
  }

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit();
  };

  createGraderRow = grader => {
    return (
      <div className="flex-row-expand" key={grader.user_name}>
        <label className="modal-inline-label">{grader.user_name}:</label>
        <input
          id={`input-${grader.user_name}`}
          type="Number"
          step="0.01"
          min="0"
          max="100"
          defaultValue={this.props.weightings[grader._id] || 1}
          onChange={event => {
            this.props.weightings[grader._id] = parseInt(event.target.value);
          }}
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
          <h2>{I18n.t("graders.weight")}:</h2>
          <div className={"modal-container-vertical"}>
            {this.props.graders.map(grader => this.createGraderRow(grader))}
          </div>
          <div className={"modal-container"}>
            <input type="submit" value={I18n.t("graders.submit")} />
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
  weightings: PropTypes.object.isRequired,
};
