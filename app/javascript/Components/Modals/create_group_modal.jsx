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

  handleChange = event => {
    this.setState({groupName: event.target.value});
  };

  handleSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.groupName);
    this.setState({groupName: ""});
  };

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="create_group_modal"
      >
        <h2>{I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})}</h2>
        <form onSubmit={this.handleSubmit}>
          <label htmlFor="groupName">{I18n.t("activerecord.models.group.one")}</label>
          <input
            id="groupName"
            type="text"
            value={this.state.groupName}
            onChange={event => this.handleChange(event)}
          />
          <div className={"modal-container"}>
            <button
              className="button"
              type="submit"
              value="Submit"
              disabled={!this.state.groupName}
            >
              {I18n.t("helpers.submit.create", {model: I18n.t("activerecord.models.group.one")})}
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
