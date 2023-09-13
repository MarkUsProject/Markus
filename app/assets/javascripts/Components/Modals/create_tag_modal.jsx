import React from "react";
import Modal from "react-modal";

class CreateTagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      isOpen: false,
      name: "",
      description: "",
      maxCharsName: 30,
      maxCharsDescription: 120,
    };
  }

  openModal = () => {
    this.setState({isOpen: true});
  };

  closeModal = () => {
    this.setState({isOpen: false});
  };

  handleNameChange = event => {
    const newName = event.target.value.slice(0, this.state.maxCharsName);
    this.setState({name: newName});
  };

  handleDescriptionChange = event => {
    const newDescription = event.target.value.slice(0, this.state.maxCharsDescription);
    this.setState({description: newDescription});
  };

  handleSubmit = () => {
    const data = {
      name: this.state.name,
      description: this.state.description,
    };
    $.ajax({
      url: Routes.course_tags_path(this.props.course_id, this.props.assignment_id),
      type: "POST",
      data: data,
    });
  };

  render() {
    return (
      this.props.readyState !== "loading" && (
        <div>
          <Modal
            isOpen={this.state.isOpen}
            onRequestClose={this.closeModal}
            contentLabel="Tag Modal"
            onSubmit={this.handleSubmit}
          >
            <span className="close" onClick={this.closeModal}>
              &times;
            </span>
            <div>
              {/*Pass in I18n*/}
              <label htmlFor="name">{this.props.nameLabel}</label>
              <textarea
                id="name"
                value={this.state.name}
                onChange={this.handleNameChange}
                maxLength={this.state.maxCharsName}
              />
              <p>Characters remaining: {this.state.maxCharsName - this.state.name.length}</p>
            </div>
            <div>
              <label htmlFor="description">{this.props.descriptionLabel}</label>
              <textarea
                id="description"
                value={this.state.description}
                onChange={this.handleDescriptionChange}
                maxLength={this.state.maxCharsDescription}
              />
              <p>
                Characters remaining:{" "}
                {this.state.maxCharsDescription - this.state.description.length}
              </p>
            </div>
          </Modal>
        </div>
      )
    );
  }
}

export function makeCreateTagModal(elem, props) {
  return React.render(<CreateTagModal {...props} />, elem);
}
