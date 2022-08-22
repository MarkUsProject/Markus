import React from "react";
import PropTypes from "prop-types";

export default class MarkdownPreview extends React.Component {
  componentDidMount = () => {
    const target_id = "annotation_preview";
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, target_id]);
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
