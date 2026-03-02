import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../common/safe_marked";
import {renderMathInElement} from "../common/math_helper";

export default class MarkdownPreview extends React.Component {
  componentDidMount = () => {
    const target_id = "annotation-preview";
    renderMathInElement(document.getElementById(target_id));
  };

  render() {
    return (
      <div
        id="annotation-preview"
        className="preview"
        dangerouslySetInnerHTML={{__html: safe_marked(this.props.content)}}
      ></div>
    );
  }
}

MarkdownPreview.propTypes = {
  content: PropTypes.string.isRequired,
  updateAnnotationCompletion: PropTypes.func,
};
