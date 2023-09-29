import React from "react";
import Modal from "react-modal";

class CreateTagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      description: "",
      maxCharsName: 30,
      maxCharsDescription: 120,
    };
  }

  // closeModal = () => {
  //   this.setState({isOpen: false});
  // };

  handleNameChange = event => {
    const newName = event.target.value.slice(0, this.state.maxCharsName);
    this.setState({name: newName});
  };

  handleDescriptionChange = event => {
    const newDescription = event.target.value.slice(0, this.state.maxCharsDescription);
    this.setState({description: newDescription});
  };

  onSubmit = event => {
    event.preventDefault();
    const data = {
      authenticity_token: this.props.authenticityToken,
      tag: {
        name: this.state.name,
        description: this.state.description,
      },
      grouping_id: this.props.grouping_id,
      commit: "Save",
    };

    const options = {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify(data),
    };
    fetch(
      Routes.course_tags_path(this.props.course_id, {assignment_id: this.props.assignment_id}),
      options
    )
      .then(response => {
        return response.json();
      })
      .then(data => {
        // Handle success
        console.log("Form submitted successfully:", data);
      })
      .catch(error => {
        // Handle errors
        console.error("Error submitting form:", error);
      });
    this.setState({
      name: "",
      description: "",
    });
    this.props.closeModal();
  };

  render() {
    return (
      this.props.loading !== "loading" && (
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.closeModal}
          id="create_new_tag"
        >
          <h1>Create Tag</h1>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <div className={"modal-container"}>
                {/*TODO Use I18n*/}
                <label htmlFor="tag_name">{this.props.nameLabel}</label>
                <textarea
                  id="tag_name"
                  value={this.state.name}
                  onChange={this.handleNameChange}
                  maxLength={this.state.maxCharsName}
                />
                <p>Characters remaining: {this.state.maxCharsName - this.state.name.length}</p>
              </div>
              <div className={"modal-container"}>
                <label className="alignleft" htmlFor="tag_description">
                  {this.props.descriptionLabel}
                </label>
                <textarea
                  id="tag_description"
                  className="clear-alignment"
                  value={this.state.description}
                  onChange={this.handleDescriptionChange}
                  maxLength={this.state.maxCharsDescription}
                />
                <p id="descript_amount" className="alignright">
                  Characters remaining:{" "}
                  {this.state.maxCharsDescription - this.state.description.length}
                </p>
              </div>
            </div>
            <button type="submit" value="Submit">
              Submit
            </button>
            <button type="reset" onClick={this.props.closeModal}>
              Cancel
            </button>
          </form>
        </Modal>
      )
    );
  }
}

// export function makeCreateTagModal(elem, props) {
//   return render(<CreateTagModal {...props} />, elem);
// }

export default CreateTagModal;
