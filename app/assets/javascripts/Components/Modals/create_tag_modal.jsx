import React from "react";
import TagModal from "../Helpers/tag_modal";
import Modal from "react-modal";
import PropTypes from "prop-types";

export default class CreateTagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      description: "",
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
      grouping_id: this.props.grouping_id,
    };
    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
      },
      body: JSON.stringify(data),
    };
    fetch(
      Routes.course_tags_path(this.props.course_id, {assignment_id: this.props.assignment_id}),
      options
    )
      .catch(error => {
        console.error(`Error submitting form: ${error.message}`);
      })
      .finally(() => {
        this.setState(
          {
            name: "",
            description: "",
          },
          () => {
            this.props.onRequestClose();
          }
        );
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
        tagModalHeading={I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.tag.one"),
        })}
        onSubmit={this.onSubmit}
      />
    );
  }
}

CreateTagModal.propType = {
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  grouping_id: PropTypes.number,
  course_id: PropTypes.number.isRequired,
  assignment_id: PropTypes.number.isRequired,
};
