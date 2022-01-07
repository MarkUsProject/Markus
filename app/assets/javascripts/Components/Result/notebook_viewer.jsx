import React from "react";
import {markupTextInRange} from "../Helpers/range_selector";

export class NotebookViewer extends React.Component {
  componentDidMount() {
    if (this.props.resultView) {
      this.readyAnnotations();
    }
  }

  readyAnnotations = () => {
    annotation_type = ANNOTATION_TYPES.NOTEBOOK;
  };

  renderAnnotations = () => {
    const iframe = document.getElementById("notebook");
    const doc = iframe.contentDocument;
    this.props.annotations.forEach(annotation => {
      const start_node = doc.evaluate(annotation.start_node, doc).iterateNext();
      const end_node = doc.evaluate(annotation.end_node, doc).iterateNext();
      const newRange = doc.createRange();
      newRange.setStart(start_node, annotation.start_offset);
      newRange.setEnd(end_node, annotation.end_offset);
      markupTextInRange(newRange, "yellow", annotation.content);
    });
  };

  render() {
    return (
      <div>
        <iframe
          className={"notebook"}
          id={"notebook"}
          key={this.props.annotations} // reload the iframe when the annotations change
          onLoad={this.renderAnnotations}
          src={this.props.url + "&preview=true"}
        />
      </div>
    );
  }
}
