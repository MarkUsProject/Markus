import React from "react";
import { render } from "react-dom";

export class TextForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.initialValue,
      unsavedChanges: false,
    };
    this.button = React.createRef();
  }

  componentDidMount() {
    this.updatePreview();
    setInterval(this.autoSaveText, 3000);
  }

  updateValue = (event) => {
    const value = event.target.value;
    this.setState({ value, unsavedChanges: true }, this.updatePreview);
  };

  updatePreview = () => {
    if (this.props.previewId) {
      document.getElementById(this.props.previewId).innerHTML = marked(
        this.state.value,
        { sanitize: true }
      );
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, this.props.previewId]);
    }
  };

  handlePersist() {
    this.props.persistChanges(this.state.value).then(() => {
      Rails.enableElement(this.button.current);
      this.setState({ unsavedChanges: false });
    });
  }

  onSubmit = (event) => {
    event.preventDefault();
    this.handlePersist();
  };

  autoSaveText = () => {
    if (this.state.unsavedChanges) {
      this.handlePersist();
    }
  };

  render() {
    return (
      <div className={this.props.className || ""}>
        <form onSubmit={this.onSubmit}>
          <textarea
            value={this.state.value}
            onChange={this.updateValue}
            rows={5}
          />
          <p>
            <input
              type="submit"
              value={I18n.t("save")}
              data-disable-with={I18n.t("working")}
              ref={this.button}
              disabled={!this.state.unsavedChanges}
            />
          </p>
        </form>
        {this.props.previewId && (
          <div>
            <h3>{I18n.t("preview")}</h3>
            <div id={this.props.previewId} className="preview" />
          </div>
        )}
      </div>
    );
  }
}
