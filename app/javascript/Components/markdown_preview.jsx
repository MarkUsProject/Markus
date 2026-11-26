import React from "react";
import PropTypes from "prop-types";

import safe_marked from "../common/safe_marked";
import {renderMathInElement} from "../common/math_helper";

export default class MarkdownPreview extends React.Component {
  static defaultProps = {
    id: "annotation-preview",
    className: "preview",
  };

  preview = React.createRef();

  componentDidMount = () => {
    renderMathInElement(this.preview.current);
  };

  componentDidUpdate = prevProps => {
    if (prevProps.content !== this.props.content) {
      renderMathInElement(this.preview.current);
    }
  };

  // Reuses the same object while the content is unchanged, so that React does not reset the
  // inner HTML and discard the rendered math
  getHtml = () => {
    if (this.html?.content !== this.props.content) {
      this.html = {content: this.props.content, value: {__html: safe_marked(this.props.content)}};
    }
    return this.html.value;
  };

  render() {
    return (
      <div
        id={this.props.id}
        ref={this.preview}
        className={this.props.className}
        dangerouslySetInnerHTML={this.getHtml()}
      ></div>
    );
  }
}

MarkdownPreview.propTypes = {
  content: PropTypes.string.isRequired,
  id: PropTypes.string,
  className: PropTypes.string,
  updateAnnotationCompletion: PropTypes.func,
};
