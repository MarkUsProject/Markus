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

  handleChange(event) {
    this.setState({value: event.target.value});
  }

  handleSubmit(event) {
    event.preventDefault();
    this.props.onSubmit(this.state.groupName);
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
        <form onSubmit={event => this.handleSubmit(event)}>
          {I18n.t("activerecord.attributes.group.group_name")}
          <div className={"modal-container"}>
            <button
              className="button"
              type="submit"
              value="Submit"
              disabled={this.state.value === undefined}
            >
              {I18n.t("groups.create_group")}
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
