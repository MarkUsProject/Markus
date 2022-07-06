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
    const weightings = {};
    const keys = Object.keys(this.input.current);
    keys.slice(0, keys.length - 1).forEach(key => {
      weightings[this.input.current[key].name] = this.input.current[key].value;
    });
    console.log(weightings);
    console.log(new FormData(this.input.current));
    this.props.onSubmit(weightings);
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
          name={`${grader._id}`}
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
        <form id="grader-form-random" onSubmit={this.onSubmit} ref={this.input}>
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
};
