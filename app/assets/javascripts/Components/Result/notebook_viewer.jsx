import React from "react";
import {markupTextInRange} from "../Helpers/range_selector";

export class NotebookViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      srcdoc: "",
    };
  }

  componentDidMount() {
    if (this.props.resultView) {
      this.readyAnnotations();
    }
    $.get(this.props.url + "&preview=true").then(res => this.setState({srcdoc: res}));
  }

  readyAnnotations = () => {
    annotation_type = ANNOTATION_TYPES.NOTEBOOK;
  };

  renderAnnotations = event => {
    const doc = event.target.contentDocument;
    const colour = document.documentElement.style.getPropertyValue("--light_alert");
    // annotations need to be sorted in the order that they were created so that multiple
    // annotations on the same node get rendered in the order they were created. If they are
    // not, then the ranges may contain nodes/offsets that don't take the other highlighted
    // regions into account. We assume that newer annotations will have a larger id than older ones.
    this.props.annotations
      .sort((a, b) => (a.id > b.id ? 1 : -1))
      .forEach(annotation => {
        const start_node = doc.evaluate(annotation.start_node, doc).iterateNext();
        const end_node = doc.evaluate(annotation.end_node, doc).iterateNext();
        const newRange = doc.createRange();
        newRange.setStart(start_node, annotation.start_offset);
        newRange.setEnd(end_node, annotation.end_offset);
        markupTextInRange(newRange, colour, annotation.content);
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
          srcDoc={this.state.srcdoc}
        />
      </div>
    );
  }
}
