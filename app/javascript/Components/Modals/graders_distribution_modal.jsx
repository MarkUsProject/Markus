import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export class GraderDistributionModal extends React.Component {
  static defaultProps = {
    override: false,
  };

  constructor(props) {
    super(props);
    this.input = React.createRef();
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    const form = new FormData(this.input.current);
    const weightings = Object.fromEntries(form);
    this.props.onSubmit(weightings);
  };

  renderGraderRow = grader => {
    return (
      <div className="flex-row-expand" key={grader.user_name}>
        <label htmlFor={`input-${grader.user_name}`} className="modal-inline-label">
          {grader.user_name}
        </label>
        <input
          className={`input-${grader.user_name}`}
          id={`input-${grader.user_name}`}
          type="number"
          step="0.01"
          min="0"
          defaultValue="1"
          name={`${grader._id}`}
          required={true}
        />
      </div>
    );
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
      >
        <form onSubmit={this.onSubmit} ref={this.input}>
          <div className={"modal-container-vertical"}>
            <h2>{I18n.t("graders.weight")}</h2>
            <p className="auto-overflow" style={{maxWidth: "300px"}}>
              {I18n.t("graders.random_instruction")}
              <a
                href={`https://github.com/MarkUsProject/Wiki/blob/${MARKUS_VERSION}/Instructor-Guide--Assignments--Assigning-Graders.md`}
              >
                {" " + I18n.t("graders.wiki")}
              </a>
            </p>
            {this.props.graders.map(grader => this.renderGraderRow(grader))}
          </div>
          <div className={"modal-container"}>
            <input type="submit" value={I18n.t("graders.actions.randomly_assign_graders")} />
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
};
