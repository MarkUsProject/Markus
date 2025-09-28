import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export default class AssignmentGroupUseModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      cloneAssignmentId: this.props.cloneAssignments || "",
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  componentDidUpdate(prevProps) {
    if (this.state.assignmentId === undefined && this.props.cloneAssignments?.length > 0) {
      this.setState({assignmentId: this.props.cloneAssignments[0].id});
    }
  }
  o;
  handleChange(event) {
    this.setState({assignmentId: event.target.value});
  }

  handleSubmit(event) {
    event.preventDefault();

    if (window.confirm(I18n.t("groups.delete_groups_linked"))) {
      this.props.onSubmit(this.state.assignmentId);
      this.props.onRequestClose();
    }
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
            value={this.state.assignmentId || ""}
            onChange={this.handleChange}
          >
            {this.props.cloneAssignments.map(assignment => (
              <option key={assignment.id} value={assignment.id}>
                {assignment.short_identifier}
              </option>
            ))}
          </select>
          <div className={"dialog-actions"}>
            <button
              className="button"
              type="submit"
              disabled={this.state.assignmentId === undefined}
            >
              {I18n.t("save")}
            </button>
            <button
              className="button"
              type="button"
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
