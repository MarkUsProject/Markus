import React from "react";
import {render} from "react-dom";

import MarkdownEditor from "../markdown_editor";

// We attempt to autosave once [saveAfterMs] has elapsed from the last user action
const saveAfterMs = 1500;

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

const SaveMessage = ({unSaved}) => (
  <div className="autosave-text">
    {unSaved ? (
      <p className="invalid-icon">{I18n.t("results.autosave.unsaved")}</p>
    ) : (
      <p className="valid-icon">{I18n.t("results.autosave.saved")}</p>
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
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.initialValue !== this.props.initialValue) {
      this.setState({value: this.props.initialValue});
    }
  }

  handlePersist = debounce(
    () => {
      this.props.persistChanges(this.state.value).then(() => {
        this.setState({unsavedChanges: false});
      });
    },
    saveAfterMs,
    false
  );

  updateValue = event => {
    const value = event.target.value;
    this.setState({value, unsavedChanges: true}, this.updatePreview);
    this.handlePersist();
  };

  render() {
    return (
      <div className={this.props.className || ""}>
        <form onSubmit={this.onSubmit}>
          <MarkdownEditor content={this.state.value} handleChange={this.updateValue} />
          <SaveMessage unSaved={this.state.unsavedChanges} />
        </form>
      </div>
    );
  }
}
