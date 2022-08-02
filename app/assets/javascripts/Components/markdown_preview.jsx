import React from "react";
import PropTypes from "prop-types";

export default class MarkdownPreview extends React.Component {
  constructor(props) {
    super(props);
  }

  componentDidMount = () => {
    const target_id = "annotation_preview";
    MathJax.Hub.Queue(["Typeset", MathJax.Hub, target_id]);
  };

  render() {
    return (
      <div
        id="annotation-preview"
        style={{
          minHeight: "10.3rem",
          padding: "10px",
        }}
      >
        {this.props.content}
      </div>
    );
  }
}

MarkdownPreview.propTypes = {
  content: PropTypes.string.isRequired,
};
