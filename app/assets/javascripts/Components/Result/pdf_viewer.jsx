import React from "react";
import {SingleSelectDropDown} from "../../DropDownMenu/SingleSelectDropDown";

export class PDFViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.pdfContainer = React.createRef();
    this.state = {
      zoom: "page-width",
      rotationInDegrees: 0,
    };
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
    } else {
      this.eventBus.on("pagesloaded", this.update_pdf_view);
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
      } else {
        this.update_pdf_view();
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

  update_pdf_view = () => {
    this.pdfViewer.currentScaleValue = this.state.zoom;
    this.pdfViewer.pagesRotation = this.state.rotationInDegrees;
  };

  refresh_annotations = () => {
    $(".annotation_holder").remove();
    this.update_pdf_view();
    this.props.annotations.forEach(this.display_annotation);
    if (!!this.props.annotationFocus) {
      document.getElementById("annotation_holder_" + this.props.annotationFocus).scrollIntoView();
    }
  };

  rotate = () => {
    if (this.props.resultView) {
      annotation_manager.rotateClockwise90();
    }

    this.setState(({rotationInDegrees}) => ({
      rotationInDegrees: (rotationInDegrees + 90) % 360,
    }));
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

    if (annotation.is_remark) {
      content += ` (${I18n.t("results.annotation.remark_flag")})`;
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
      annotation.id,
      annotation.is_remark
    );
  };

  getZoomValuesToDisplayName = () => {
    const zoomLevels = Array.from({length: 20}, (_, i) => ((i + 1) * 0.1).toFixed(1));

    const valueToDisplayName = zoomLevels.reduce(
      (acc, value) => {
        acc[value] = `${(value * 100).toFixed(0)} %`;
        return acc;
      },
      {"page-width": I18n.t("results.fit_to_page_width")}
    );

    return valueToDisplayName;
  };

  render() {
    const cursor = this.props.released_to_students ? "default" : "crosshair";
    const userSelect = this.props.released_to_students ? "default" : "none";
    const zoomValuesToDisplayName = this.getZoomValuesToDisplayName();

    return (
      <div>
        <div className="toolbar">
          <div className="toolbar-actions">
            {I18n.t("results.current_rotation", {rotation: this.state.rotationInDegrees})}
            <button onClick={this.rotate} className={"inline-button"}>
              {I18n.t("results.rotate_image")}
            </button>
            <span style={{marginLeft: "7px"}}>{I18n.t("results.zoom")}</span>
            <SingleSelectDropDown
              valueToDisplayName={zoomValuesToDisplayName}
              options={Object.keys(zoomValuesToDisplayName)}
              selected={this.state.zoom}
              dropdownStyle={{minWidth: "auto", marginLeft: "5px", width: "150px"}}
              selectionStyle={{minWidth: "auto", width: "100px", marginRight: "0px"}}
              hideXMark={true}
              onSelect={selection => {
                this.setState({zoom: selection});
              }}
            />
          </div>
        </div>
        <div className="pdfContainerParent">
          <div
            id="pdfContainer"
            className="pdfContainer"
            style={{cursor, userSelect, overflow: "auto"}}
            ref={this.pdfContainer}
          >
            <div id="viewer" className="pdfViewer" />
            <div
              key="sel_box"
              id="sel_box"
              className="annotation-holder-active"
              style={{display: "none"}}
            />
          </div>
        </div>
      </div>
    );
  }
}
