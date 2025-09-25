import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export default class AssignmentGroupUseModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assignmentId: null,
    };
  }

  componentDidUpdate() {
    if (this.state.value === undefined && this.props.examTemplates.length > 0) {
      this.setState({value: this.props.examTemplates[0].id});
    }
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  handleChange(event) {
    this.setState({assignmentId: event.target.value});
  }

  handleSubmit(event) {
    this.props.onSubmit(this.state.value);
    this.props.onRequestClose();
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="assignment_group_use_modal"
      >
        <h2>{I18n.t("groups.reuse_groups")}</h2>
        <form onSubmit={this.handleSubmit}>
          {I18n.t("groups.assignment_to_use")}
          <select
            id="assignment-group-select"
            value={this.state.value}
            onChange={this.handleChange}
          >
            {this.props.cloneAssignments.map(assignment => (
              <option key={assignment.id} value={assignment.id}>
                {assignment.short_identifier}
              </option>
            ))}
          </select>
          <div className={"dialog-actions"}>
            <button className="button" type="submit" disabled={this.state.value === undefined}>
              {I18n.t("save")}
            </button>
            <button
              className="button"
              type="reset"
              id="assignment-group-use-close"
              onClick={this.props.onRequestClose}
            >
              {I18n.t("cancel")}
            </button>
          </div>
        </form>
      </Modal>
    );
  }
}
