import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../common/safe_marked";

export default class MarkdownPreview extends React.Component {
  componentDidMount = () => {
    const target_id = "#annotation-preview";
    MathJax.typeset([target_id]);
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
