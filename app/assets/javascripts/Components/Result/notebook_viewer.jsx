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

  renderAnnotations = event => {
    const doc = event.target.contentDocument;
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
        newRange.setStart(start_node, annotation.start_offset);
        newRange.setEnd(end_node, annotation.end_offset);
        markupTextInRange(newRange, annotation.content);
      });
  };

  render() {
    return (
      <div>
        <iframe
          className={"notebook"}
          id={"notebook"}
          key={this.props.annotations.map(a => [a.id, a.annotation_text_id])} // reload when the annotations change
          onLoad={this.renderAnnotations}
          src={this.props.url + "&preview=true"}
        />
      </div>
    );
  }
}
