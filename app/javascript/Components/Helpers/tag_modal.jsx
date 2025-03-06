import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";

export default class TagModal extends React.Component {
  constructor(props) {
    super(props);
    this.maxCharsName = 30;
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="tag_modal"
      >
        <div data-testid="tag_modal">
          <h1 data-testid="tag_modal_heading">{this.props.tagModalHeading}</h1>
          <form onSubmit={this.props.onSubmit}>
            <div className="modal-container-vertical">
              <p className="alignleft" data-testid="tag_name_label">
                {I18n.t("activerecord.attributes.tags.name")} ({this.props.name.length} /
                {this.maxCharsName})
              </p>
              <textarea
                required={true}
                id="tag_name"
                data-testid="tag_name_input"
                className="clear-alignment"
                role="textbox"
                value={this.props.name}
                onChange={this.props.handleNameChange}
                maxLength={this.maxCharsName}
              />
              <p className="alignleft" data-testid="tag_description_label">
                {I18n.t("activerecord.attributes.tags.description")}
              </p>
              <textarea
                id="tag_description"
                className="clear-alignment"
                role="textbox"
                data-testid="tag_description_input"
                value={this.props.description}
                onChange={this.props.handleDescriptionChange}
                rows={3}
              />
            </div>
            <div className={"modal-container"}>
              <button
                type="submit"
                value="Submit"
                data-testid="tag_submit_button"
                disabled={!this.props.name}
              >
                {I18n.t("save")}
              </button>
              <button
                type="reset"
                data-testid="tag_cancel_button"
                onClick={this.props.onRequestClose}
              >
                {I18n.t("cancel")}
              </button>
            </div>
          </form>
        </div>
      </Modal>
    );
  }
}

TagModal.propTypes = {
  name: PropTypes.string.isRequired,
  description: PropTypes.string.isRequired,
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  tagModalHeading: PropTypes.string.isRequired,
  onSubmit: PropTypes.func.isRequired,
  handleNameChange: PropTypes.func.isRequired,
  handleDescriptionChange: PropTypes.func.isRequired,
};
