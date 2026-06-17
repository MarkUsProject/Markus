import React from "react";
import {SingleSelectDropDown} from "../DropDown/SingleSelectDropDown";
import {PdfAnnotationManager} from "../../common/annotations/pdf_annotation_manager";
import {ResultContext} from "./result_context";

// Frame budget for restoring scroll: enough to wait out pdf.js's async layout and
// re-assert the position past its scroll-to-top reset (~40 frames ≈ 0.65s).
const MAX_SCROLL_RESTORE_FRAMES = 40;

export class PDFViewer extends React.PureComponent {
  static contextType = ResultContext;

  constructor(props) {
    super(props);
    this.pdfContainer = React.createRef();
    this.scrollContainer = React.createRef();
    this.savedScrollPosition = null;
    this.scrollRestoreFrame = null;
    this.zoomValuesToDisplayName = this.getZoomValuesToDisplayName();
    this.state = {
      zoom: "page-width",
      rotation: 0, // NOTE: this is in degrees
    };
  }

  componentDidMount() {
    this.eventBus = new pdfjsViewer.EventBus();
    this.pdfViewer = new pdfjsViewer.PDFViewer({
      eventBus: this.eventBus,
      container: this.pdfContainer.current,
    });
    window.pdfViewer = this; // For fixing display when pane width changes

    if (this.props.resultView) {
      this.eventBus.on("pagesinit", this.ready_annotations);
      this.eventBus.on("pagesloaded", this.refresh_annotations);
      this.eventBus.on("pagesloaded", this.restore_scroll_position);
    } else {
      this.eventBus.on("pagesloaded", this.update_pdf_view);
    }

    this.loadedSubmissionId = this.context.submission_id;
    if (this.props.url) {
      this.loadPDFFile();
    }
  }

  componentDidUpdate(prevProps) {
    if (this.props.url && this.props.url !== prevProps.url) {
      if (this.context.submission_id !== this.loadedSubmissionId) {
        // Submission switch: carry the scroll position over to the next PDF.
        this.save_scroll_position();
      } else {
        // Different file within the same submission: open it at the top.
        this.savedScrollPosition = null;
      }
      this.loadedSubmissionId = this.context.submission_id;
      this.loadPDFFile();
    } else if (this.props.resultView) {
      this.refresh_annotations();
    } else {
      this.update_pdf_view();
    }
  }

  loadPDFFile = () => {
    pdfjs.getDocument(this.props.url).promise.then(pdfDocument => {
      this.pdfViewer.setDocument(pdfDocument);
      this.props.setLoadingCallback(false);
    });
  };

  ready_annotations = () => {
    window.annotation_type = window.ANNOTATION_TYPES.PDF;

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
    this.cancel_scroll_restore();
  }

  cancel_scroll_restore = () => {
    if (!this.scrollRestoreFrame) return;
    cancelAnimationFrame(this.scrollRestoreFrame);
    this.scrollRestoreFrame = null;
  };

  // For scanned exams, preserve the scroll position across submission switches
  // so TAs grading one question on a shared page don't re-scroll every time.
  save_scroll_position = () => {
    if (!this.context.scanned_exam || !this.scrollContainer.current) return;

    const {scrollTop, scrollLeft} = this.scrollContainer.current;
    this.savedScrollPosition = {top: scrollTop, left: scrollLeft};
  };

  restore_scroll_position = () => {
    this.cancel_scroll_restore();
    if (
      !this.context.scanned_exam ||
      this.savedScrollPosition === null ||
      this.props.annotationFocus
    ) {
      return;
    }

    // pdf.js loads the new document asynchronously: it un-hides the viewer, lays
    // out the pages, and resets the scroll to the top — and any of those can land
    // after a single scrollTop write, so the position intermittently snaps back.
    // Re-assert every frame until the container can hold the offset and the
    // position has stuck for two consecutive frames (or we exhaust the budget).
    const {top, left} = this.savedScrollPosition;
    let attempts = 0;
    let heldFrames = 0;
    const apply = () => {
      this.scrollRestoreFrame = null;
      const scrollParent = this.scrollContainer.current;
      if (!scrollParent) return;

      const reschedule = () => {
        attempts += 1;
        if (attempts < MAX_SCROLL_RESTORE_FRAMES) {
          this.scrollRestoreFrame = requestAnimationFrame(apply);
        }
      };

      // Not ready yet: still hidden, or pages too short to hold the offset.
      const hasRoom = scrollParent.scrollHeight - scrollParent.clientHeight >= top;
      if (scrollParent.offsetParent === null || !hasRoom) {
        reschedule();
        return;
      }

      if (Math.abs(scrollParent.scrollTop - top) <= 1) {
        heldFrames += 1;
      } else {
        scrollParent.scrollTop = top;
        scrollParent.scrollLeft = left;
        heldFrames = 0;
      }
      if (heldFrames < 2) reschedule();
    };
    this.scrollRestoreFrame = requestAnimationFrame(apply);
  };

  update_pdf_view = () => {
    const container = document.getElementById("pdfContainer");
    if (container && container.offsetParent) {
      this.pdfViewer.currentScaleValue = this.state.zoom;
      this.pdfViewer.pagesRotation = this.state.rotation;
    }
  };

  refresh_annotations = () => {
    $(".annotation_holder").remove();
    this.update_pdf_view();
    this.props.annotations.forEach(this.display_annotation);
    if (this.props.annotationFocus) {
      document.getElementById("annotation_holder_" + this.props.annotationFocus).scrollIntoView();
    }
  };

  rotate = () => {
    if (this.props.resultView) {
      annotation_manager.rotateClockwise90();
    }

    this.setState(({rotation}) => ({
      rotation: (rotation + 90) % 360,
    }));
  };

  display_annotation = annotation => {
    if (annotation.x_range === undefined || annotation.y_range === undefined) {
      return;
    }
    let content = annotation.content;
    if (annotation.deduction) {
      content += ` [${annotation.criterion_name}: -${annotation.deduction}]`;
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
    const valueToDisplayName = {"page-width": I18n.t("results.fit_to_page_width")};
    // 25%-200% in increments of 25%
    for (let percent = 25; percent <= 200; percent += 25) {
      valueToDisplayName[(percent / 100).toFixed(2)] = `${percent} %`;
    }
    return valueToDisplayName;
  };

  render() {
    const cursor = this.props.released_to_students ? "default" : "crosshair";
    const userSelect = this.props.released_to_students ? "default" : "none";
    const zoomValuesToDisplayName = this.zoomValuesToDisplayName;

    return (
      <React.Fragment>
        <div className="toolbar">
          <div className="toolbar-actions">
            {I18n.t("results.current_rotation", {rotation: this.state.rotation})}
            <button onClick={this.rotate} className={"inline-button"}>
              {I18n.t("results.rotate_image")}
            </button>
            <span style={{marginLeft: "7px"}}>{I18n.t("results.zoom")}</span>
            <SingleSelectDropDown
              valueToDisplayName={zoomValuesToDisplayName}
              options={Object.keys(zoomValuesToDisplayName)}
              selected={this.state.zoom}
              dropdownStyle={{
                minWidth: "auto",
                width: "fit-content",
                marginLeft: "5px",
                verticalAlign: "middle",
              }}
              selectionStyle={{width: "90px", marginRight: "0px"}}
              hideXMark={true}
              onSelect={selection => {
                this.setState({zoom: selection});
              }}
            />
          </div>
        </div>
        <div className="pdfContainerParent" ref={this.scrollContainer}>
          <div
            id="pdfContainer"
            className="pdfContainer"
            style={{cursor, userSelect}}
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
      </React.Fragment>
    );
  }
}
