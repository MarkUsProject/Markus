import React from "react";
import { render } from "react-dom";

function debounce(func, wait, immediate) {
  var timeout;

  return function executedFunction() {
    var context = this;
    var args = arguments;

    var later = function () {
      timeout = null;
      if (!immediate) func.apply(context, args);
    };

    var callNow = immediate && !timeout;

    clearTimeout(timeout);

    timeout = setTimeout(later, wait);

    if (callNow) func.apply(context, args);
  };
}

const SaveMessage = ({ unSaved }) => (
  <div className="autosave-text">
    {unSaved ? (
      <p> There are unsaved changes </p>
    ) : (
      <p> Changes have been saved </p>
    )}
  </div>
);

export class TextForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: props.initialValue,
      unsavedChanges: false,
    };
    this.autoSaveText = this.autoSaveText.bind(this);
  }

  componentDidMount() {
    this.updatePreview();
    setInterval(this.autoSaveText, 3000);
  }

  handlePersist = debounce(
    () => {
      this.props.persistChanges(this.state.value).then(() => {
        this.setState({ unsavedChanges: false });
      });
    },
    1500,
    false
  );

  updateValue = (event) => {
    const value = event.target.value;
    this.setState({ value, unsavedChanges: true }, this.updatePreview);
    this.handlePersist();
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

  autoSaveText() {
    if (this.state.unsavedChanges) {
      this.handlePersist();
    }
  }

  render() {
    return (
      <div className={this.props.className || ""}>
        <form onSubmit={this.onSubmit}>
          <textarea
            value={this.state.value}
            onChange={this.updateValue}
            rows={5}
          />
          <SaveMessage unSaved={this.state.unsavedChanges} />
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
