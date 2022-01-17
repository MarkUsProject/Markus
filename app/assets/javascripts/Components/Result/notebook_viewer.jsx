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
    this.props.annotations.forEach(annotation => {
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
