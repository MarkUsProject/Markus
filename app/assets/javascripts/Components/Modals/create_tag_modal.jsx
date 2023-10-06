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
      .catch(error => {
        console.error("Error submitting form: ", error);
      })
      .then(() => {
        this.setState(
          {
            name: "",
            description: "",
          },
          () => {
            this.props.closeModal();
          }
        );
      })
      .catch(error => {
        console.error(error);
      });
  };

  /**
   * TODO:
   * React related:
   * 1) should resize? Use Resizable or write own with ref? Can tolerate predefined width & height? Draggable?
   * 2) "appElement={document.getElementById('root') || undefined}" needed? Better alternatives?
   * 3) dim background when modal open? Possible props from react-modal / css?
   * 4) replace edit tag modal as well
   * 5) safe to add auth token in data? In header instead?
   * General:
   * 1) remove unnecessary console logs (if any left) added for debugging
   */
  render() {
    return (
      this.props.loading !== "loading" && (
        <Modal
          appElement={document.getElementById("root") || undefined}
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.closeModal}
          id="create_new_tag"
        >
          <h1>
            {I18n.t("helpers.submit.create", {
              model: I18n.t("activerecord.models.tag.one"),
            })}
          </h1>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <p className="alignleft">{I18n.t("activerecord.attributes.tags.name")}:</p>
              <textarea
                required={true}
                id="tag_name"
                className="clear-alignment"
                value={this.state.name}
                onChange={this.handleNameChange}
                maxLength={this.state.maxCharsName}
              />
              <p id="name_amount" className="alignright">
                {this.state.name.length} / {this.state.maxCharsName}
              </p>
              <p className="alignleft">{I18n.t("activerecord.attributes.tags.description")}:</p>
              <textarea
                id="tag_description"
                className="clear-alignment"
                value={this.state.description}
                onChange={this.handleDescriptionChange}
                maxLength={this.state.maxCharsDescription}
              />
              <p id="description_amount" className="alignright">
                {this.state.description.length} / {this.state.maxCharsDescription}
              </p>
            </div>
            <div className={"modal-container"}>
              <button type="submit" value="Submit" disabled={!this.state.name}>
                {I18n.t("save")}
              </button>
              <button type="reset" onClick={this.props.closeModal}>
                {I18n.t("cancel")}
              </button>
            </div>
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
