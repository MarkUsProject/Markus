import React from "react";
import Modal from "react-modal";
import TagModal from "../Helpers/tag_modal";
import PropTypes from "prop-types";

export default class EditTagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: this.props.currentTagName,
      description: this.props.currentTagDescription,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  onSubmit = event => {
    event.preventDefault();
    const data = {
      tag: {
        name: this.state.name,
        description: this.state.description,
      },
      course_id: this.props.course_id,
      id: this.props.tag_id,
      submit: "Save",
    };
    const options = {
      method: "PUT",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify(data),
    };
    fetch(Routes.course_tag_path(this.props.course_id, this.props.tag_id), options)
      .then(() => {
        this.props.onRequestClose();
      })
      .catch(error => {
        console.error(error.message);
      });
  };

  render() {
    return (
      <TagModal
        name={this.state.name}
        description={this.state.description}
        handleNameChange={event => this.setState({name: event.target.value})}
        handleDescriptionChange={event => this.setState({description: event.target.value})}
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        tagModalHeading={I18n.t("helpers.submit.update", {
          model: I18n.t("activerecord.models.tag.one"),
        })}
        onSubmit={this.onSubmit}
      />
    );
  }
}

EditTagModal.propType = {
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  tag_id: PropTypes.number.isRequired,
  course_id: PropTypes.number.isRequired,
  assignment_id: PropTypes.number.isRequired,
  currentTagName: PropTypes.string.isRequired,
  currentTagDescription: PropTypes.string.isRequired,
};
