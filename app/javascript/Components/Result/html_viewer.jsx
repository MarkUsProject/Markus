import React from "react";
import {markupTextInRange} from "../Helpers/range_selector";

export class HTMLViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.iframe = React.createRef();
  }

  componentDidMount() {
    if (this.props.resultView) {
      this.readyAnnotations();
    }
  }

  readyAnnotations = () => {
    annotation_type = ANNOTATION_TYPES.HTML;
  };

  renderAnnotations = () => {
    const doc = this.iframe.current.contentWindow.document;
    // annotations need to be sorted in the order that they were created so that multiple
    // annotations on the same node get rendered in the order they were created. If they are
    // not, then the ranges may contain nodes/offsets that don't take the other highlighted
    // regions into account.
    this.props.annotations
      .sort((a, b) => (a.number > b.number ? 1 : -1))
      .forEach(annotation => {
        const start_node = doc.evaluate(annotation.start_node, doc).iterateNext();
        const end_node = doc.evaluate(annotation.end_node, doc).iterateNext();
        const newRange = doc.createRange();
        try {
          if (doc.getElementById(`markus-annotation-${annotation.id}`) === null) {
            newRange.setStart(start_node, annotation.start_offset);
            newRange.setEnd(end_node, annotation.end_offset);
          } else {
            // Dummy values for the range
            newRange.setStart(start_node, 0);
            newRange.setEnd(end_node, 0);
          }
          markupTextInRange(newRange, annotation.content, annotation.id);
        } catch (error) {
          console.error(error);
        }
      });
  };

  componentDidUpdate(prevProps) {
    if (prevProps.annotations !== this.props.annotations) {
      // If annotations have been deleted, reload the notebook.
      // TODO: Remove this after implementing functionality to manually remove
      //       an annotation (likely in range_selector.js).
      if (prevProps.annotations.length > this.props.annotations.length) {
        this.iframe.current.contentWindow.location.reload();
      }
      this.renderAnnotations();
    }
  }

  render() {
    return (
      <div>
        <iframe
          className={"html-content"}
          id={"html-content"}
          key={this.props.url}
          onLoad={this.renderAnnotations}
          src={this.props.url + "&preview=true"}
          ref={this.iframe}
          sandbox="allow-same-origin allow-scripts"
        />
      </div>
    );
  }
}
