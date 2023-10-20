import React from "react";
import Modal from "react-modal";

export default class EditTagModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      name: this.props.currentTagName,
      description: this.props.currentTagDescription,
      maxCharsName: 30,
      maxCharsDescription: 120,
    };
  }

  componentDidMount() {
    Modal.setAppElement("body");
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
        "X-CSRF-Token": AUTH_TOKEN,
      },
      body: JSON.stringify(data),
    };
    fetch(Routes.course_tag_path(this.props.course_id, this.props.tag_id), options)
      .catch(error => {
        console.error("Error submitting form: ", error);
      })
      .then(() => {
        this.props.closeModal();
      })
      .catch(error => {
        console.error(error);
      });
  };

  /**
   * TODO:
   * React related:
   * 2) "appElement={document.getElementById('root') || undefined}" needed? Better alternatives?
   * 3) dim background when modal open? Possible props from react-modal / css?
   * 4) replace edit tag modal as well
   * General:
   * 1) remove unnecessary console logs (if any left) added for debugging
   */
  render() {
    return (
      this.props.loading !== "loading" && (
        <Modal
          className="react-modal dialog"
          isOpen={this.props.isOpen}
          onRequestClose={this.props.closeModal}
          id="edit_tag"
        >
          <h1>
            {I18n.t("helpers.submit.update", {
              model: I18n.t("activerecord.models.tag.one"),
            })}
          </h1>
          <form onSubmit={this.onSubmit}>
            <div className={"modal-container-vertical"}>
              <p className="alignleft">
                {I18n.t("activerecord.attributes.tags.name")} ({this.state.name.length} /{" "}
                {this.state.maxCharsName})
              </p>
              <textarea
                required={true}
                id="tag_name"
                className="clear-alignment"
                value={this.state.name}
                onChange={this.handleNameChange}
                maxLength={this.state.maxCharsName}
              />
              <p className="alignleft">
                {I18n.t("activerecord.attributes.tags.description")} (
                {this.state.description.length} / {this.state.maxCharsDescription})
              </p>
              <textarea
                id="tag_description"
                className="clear-alignment"
                value={this.state.description}
                onChange={this.handleDescriptionChange}
                maxLength={this.state.maxCharsDescription}
              />
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

// export default CreateTagModal;
