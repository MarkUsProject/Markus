import React from "react";
import Modal from "react-modal";
import PropTypes from "prop-types";
import {ResultContext} from "../Result/result_context";

export default class AutoMatchModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: this.props.examTemplates.length === 0 ? undefined : this.props.examTemplates[0].id,
    };
  }

  static contextType = ResultContext;

  componentDidUpdate() {
    if (this.state.value === undefined && this.props.examTemplates.length > 0) {
      this.setState({value: this.props.examTemplates[0].id});
    }
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  handleChange(event) {
    this.setState({value: event.target.value});
  }

  handleSubmit(event) {
    this.props.onSubmit(this.state.value);
    this.props.onRequestClose();
  }

  render() {
    return (
      <Modal
        className="react-modal markus-dialog"
        isOpen={this.props.isOpen}
        onRequestClose={this.props.onRequestClose}
        id="auto_match_modal"
      >
        <h2>{I18n.t("groups.auto_match")}</h2>
        <form onSubmit={event => this.handleSubmit(event)}>
          {I18n.t("activerecord.models.exam_template.one")}
          <select
            id="auto-match-select"
            value={this.state.value}
            onChange={event => this.handleChange(event)}
          >
            {this.props.examTemplates.map(examTemplate => (
              <option key={examTemplate.id} value={examTemplate.id}>
                {examTemplate.name}
              </option>
            ))}
          </select>
          <div className={"modal-container"}>
            <button
              className="button"
              type="submit"
              value="Submit"
              disabled={this.state.value === undefined}
            >
              {I18n.t("groups.auto_match")}
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

AutoMatchModal.propType = {
  isOpen: PropTypes.bool.isRequired,
  onRequestClose: PropTypes.func.isRequired,
  examTemplates: PropTypes.array.isRequired,
  onSubmit: PropTypes.func.isRequired,
};
