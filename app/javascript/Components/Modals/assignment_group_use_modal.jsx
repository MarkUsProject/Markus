import React from "react";
import Modal from "react-modal";

export default class AssignmentGroupUseModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assignmentId: "",
      isLoading: false,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  componentDidUpdate(prevProps) {
    if (this.props.isOpen && !prevProps.isOpen) {
      if (this.props.cloneAssignments.length > 0) {
        this.setState({
          assignmentId: this.props.cloneAssignments[0].id,
        });
      } else {
        this.setState({
          assignmentId: "",
        });
      }
    }
  }

  handleChange = event => {
    this.setState({assignmentId: event.target.value});
  };

  handleSubmit = event => {
    event.preventDefault();
    if (window.confirm(I18n.t("groups.delete_groups_linked"))) {
      this.setState({isLoading: true});
      this.props.onSubmit(this.state.assignmentId);
    }
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="assignment-group-use"
      >
        <h2>{I18n.t("groups.reuse_groups")}</h2>
        <form onSubmit={this.handleSubmit}>
          {I18n.t("groups.assignment_to_use")}
          <select
            id="assignment-group-select"
            value={this.state.assignmentId}
            onChange={event => this.handleChange(event)}
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
              disabled={
                !this.state.assignmentId ||
                this.props.cloneAssignments.length === 0 ||
                this.state.isLoading
              }
            >
              {this.state.isLoading ? I18n.t("working") : I18n.t("save")}
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
