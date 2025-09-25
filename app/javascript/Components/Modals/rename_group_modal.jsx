import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export default class RenameGroupModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      groupName: "",
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  componentDidUpdate(prevProps) {
    if (this.props.isOpen && !prevProps.isOpen && this.props.currentGroupName) {
      this.setState({groupName: this.props.currentGroupName});
    }
  }

  handleChange = event => {
    this.setState({groupName: event.target.value});
  };

  handleSubmit = event => {
    event.preventDefault();
    if (!this.state.groupName) {
      return this.props.onRequestClose();
    }
    this.props.onSubmit(this.state.groupName);
    this.setState({groupName: ""});
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="rename_group_dialog"
      >
        <h2>{I18n.t("groups.rename_group")}</h2>
        <form onSubmit={this.handleSubmit}>
          <label htmlFor="groupName">{I18n.t("activerecord.attributes.group.group_name")}</label>
          <input
            id="groupName"
            type="text"
            value={this.state.groupName}
            onChange={event => this.handleChange(event)}
            autoFocus
          />
          <div className={"dialog-actions"}>
            <button
              className="button"
              type="submit"
              disabled={!this.state.groupName}
              data-testid="rename-submit-button"
            >
              {I18n.t("groups.rename_group")}
            </button>
            <button className="button" type="reset" onClick={this.props.onRequestClose}>
              {I18n.t("cancel")}
            </button>
          </div>
        </form>
      </Modal>
    );
  }
}
