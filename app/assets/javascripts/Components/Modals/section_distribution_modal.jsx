import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export class SectionDistributionModal extends React.Component {
  static defaultProps = {
    override: false,
  };

  constructor(props) {
    super(props);
    this.input = React.createRef();
    this.sectionsArray = Object.values(this.props.sections);
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    const form = new FormData(this.input.current);
    const assignments = {};
    form.forEach((value, key) => {
      assignments[key] = value;
    });
    this.props.onSubmit(assignments);
  };

  renderSectionRow = section => {
    const {graders} = this.props;
    return (
      <div className="flex-row-expand" key={section}>
        <label htmlFor={`input-${section}`} className="modal-inline-label">
          {section}
        </label>
        <select className={`input-${section}`} name={section}>
          <option value="">Select TA</option>
          {graders.map(grader => (
            <option key={grader.user_name} value={grader.user_name}>
              {grader.user_name}
            </option>
          ))}
        </select>
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
        <form onSubmit={this.onSubmit} ref={this.input}>
          <div className={"modal-container-vertical"}>
            <h2>Distribute TAs to Sections</h2>
            {this.sectionsArray.map(section => this.renderSectionRow(section))}
          </div>
          <div className={"modal-container"}>
            <input type="submit" value="Assign TAs" />
          </div>
        </form>
      </Modal>
    );
  }
}

SectionDistributionModal.propTypes = {
  graders: PropTypes.arrayOf(PropTypes.object).isRequired,
  isOpen: PropTypes.bool.isRequired,
  onSubmit: PropTypes.func.isRequired,
  sections: PropTypes.objectOf(PropTypes.string).isRequired,
};
