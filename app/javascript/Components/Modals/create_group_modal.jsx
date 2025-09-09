import React from "react";
import Modal from "react-modal";

export default class CreateGroupModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      groupName: "",
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  handleChange = (event) => {
    this.setState({groupName: event.target.value});
  }

  handleSubmit = (event) => {
    event.preventDefault();
    this.props.handleSubmitCreateGroup(this.state.groupName);
    this.setState({groupName: ""});
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="create_group_modal"
      >
        <h2>{I18n.t("groups.create_group")}</h2>
        <form onSubmit={this.handleSubmit}>
          {I18n.t("activerecord.attributes.group.group_name")}
          <input
            type="text"
            value={this.state.groupName}
            onChange={this.handleChange}
          />
          <div className={"modal-container"}>
            <button
              className="button"
              type="submit"
              disabled={!this.state.groupName}
            >
              {I18n.t("groups.create_group")}
            </button>
            <button className="button" type="button" onClick={this.props.onRequestClose}>
              {I18n.t("cancel")}
            </button>
          </div>
        </form>
      </Modal>
    );
  }
}
