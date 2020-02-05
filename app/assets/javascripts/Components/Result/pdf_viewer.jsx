import React from 'react';


export class PDFViewer extends React.Component {
  constructor(props) {
    super(props);
    this.pdfContainer = React.createRef();
  }

  componentDidMount() {
    if (this.props.url) {
      this.pdfViewer = new pdfjsViewer.PDFViewer({
        container: this.pdfContainer.current,
        renderer: 'svg',
      });
      this.loadPDFFile();
      window.pdfViewer = this.pdfViewer;  // For fixing display when pane width changes
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.url && this.props.url !== prevProps.url) {
      this.loadPDFFile();
    } else {
      $('.annotation_holder').remove();
      this.props.annotations.forEach(this.display_annotation);
    }
  }

  loadPDFFile = () => {
    pdfjs.getDocument(this.props.url).promise.then((pdfDocument) => {
      this.pdfViewer.setDocument(pdfDocument);

      document.addEventListener('pagesinit', () => {
        this.pdfViewer.currentScaleValue = 'page-fit';
        this.ready_annotations(this.pdfViewer, 'viewer');
      });

      document.addEventListener('pagesloaded', () => {
        this.props.annotations.forEach(this.display_annotation);
      });
    });
  };

  ready_annotations = (pdfView, pdfViewerId) => {
    annotation_type = ANNOTATION_TYPES.PDF;

    window.annotation_manager = new PdfAnnotationManager(pdfView, pdfViewerId, !this.props.released_to_students);
    window.annotation_manager.resetAngle();
  };

  componentWillUnmount() {
    let box = document.getElementById('sel_box');
    if (box) {
      box.style.display = 'none';
      box.style.width   = '0';
      box.style.height  = '0';
    }
  }

  display_annotation = (annotation) => {
    if (annotation.x_range === undefined || annotation.y_range === undefined) {
      return;
    }

    add_annotation_text(annotation.annotation_text_id, marked(annotation.content, {sanitize: true}));
    annotation_manager.addAnnotation(
      annotation.annotation_text_id,
      marked(annotation.content, {sanitize: true}),
      {
        x1: annotation.x_range.start,
        x2: annotation.x_range.end,
        y1: annotation.y_range.start,
        y2: annotation.y_range.end,
        page: annotation.page,
        annot_id: annotation.id
      }
    );
  };

  rotate = () => {
    annotation_manager.hideSelectionBox();
    annotation_manager.rotateClockwise90();
    this.pdfViewer.rotatePages(90);
  };

  render() {
    const cursor = this.props.released_to_students ? 'default' : 'crosshair';
    const userSelect = this.props.released_to_students? 'default' : 'none';
    return (
      <div>
        <div id="pdfContainer" style={{cursor, userSelect}} ref={this.pdfContainer}>
          <div id="viewer" className="pdfViewer" />
        </div>
      </div>
    );
  }
}
