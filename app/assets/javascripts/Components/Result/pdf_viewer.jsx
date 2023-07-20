import React from "react";

export class PDFViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.pdfContainer = React.createRef();
  }

  componentDidMount() {
    this.eventBus = new pdfjsViewer.EventBus();
    this.pdfViewer = new pdfjsViewer.PDFViewer({
      eventBus: this.eventBus,
      container: this.pdfContainer.current,
      // renderer: 'svg',  TODO: investigate why some fonts don't render with SVG
    });
    window.pdfViewer = this; // For fixing display when pane width changes

    if (this.props.resultView) {
      this.eventBus.on("pagesinit", this.ready_annotations);
      this.eventBus.on("pagesloaded", this.refresh_annotations);
    }

    if (this.props.url) {
      this.loadPDFFile();
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.url && this.props.url !== prevProps.url) {
      this.loadPDFFile();
    } else {
      if (this.props.resultView) {
        this.refresh_annotations();
      }
    }
  }

  loadPDFFile = () => {
    pdfjs.getDocument(this.props.url).promise.then(pdfDocument => {
      this.pdfViewer.setDocument(pdfDocument);
    });
  };

  ready_annotations = () => {
    annotation_type = ANNOTATION_TYPES.PDF;

    this.pdfViewer.currentScaleValue = "page-width";
    window.annotation_manager = new PdfAnnotationManager(!this.props.released_to_students);
    window.annotation_manager.resetAngle();
    this.annotation_manager = window.annotation_manager;
  };

  componentWillUnmount() {
    let box = document.getElementById("sel_box");
    if (box) {
      box.style.display = "none";
      box.style.width = "0";
      box.style.height = "0";
    }
    this.eventBus = null;
    window.pdfViewer = undefined;
  }

  refresh_annotations = () => {
    $(".annotation_holder").remove();
    this.pdfViewer.currentScaleValue = "page-width";
    this.props.annotations.forEach(this.display_annotation);
    if (!!this.props.annotationFocus) {
      document.getElementById("annotation_holder_" + this.props.annotationFocus).scrollIntoView();
    }
  };

  display_annotation = annotation => {
    if (annotation.x_range === undefined || annotation.y_range === undefined) {
      return;
    }
    let content = "";
    if (!annotation.deduction) {
      content += annotation.content;
    } else {
      content +=
        annotation.content + " [" + annotation.criterion_name + ": -" + annotation.deduction + "]";
    }

    this.annotation_manager.addAnnotation(
      annotation.annotation_text_id,
      safe_marked(content),
      {
        x1: annotation.x_range.start,
        x2: annotation.x_range.end,
        y1: annotation.y_range.start,
        y2: annotation.y_range.end,
        page: annotation.page,
      },
      annotation.id
    );
  };

  rotate = () => {
    annotation_manager.rotateClockwise90();
    this.pdfViewer.rotatePages(90);
  };

  render() {
    const cursor = this.props.released_to_students ? "default" : "crosshair";
    const userSelect = this.props.released_to_students ? "default" : "none";
    return (
      <div>
        <div id="pdfContainer" style={{cursor, userSelect}} ref={this.pdfContainer}>
          <div id="viewer" className="pdfViewer" />
          <div
            key="sel_box"
            id="sel_box"
            className="annotation-holder-active"
            style={{display: "none"}}
          />
        </div>
      </div>
    );
  }
}
