import React from "react";
import heic2any from "heic2any";

export class ImageViewer extends React.PureComponent {
  constructor(props) {
    super(props);
    this.state = {
      rotation: window.start_image_rotation || 0,
      zoom: window.start_image_zoom || 1,
      url: null,
    };
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.url && this.props.url !== prevProps.url) {
      this.setImageURL().then(() => {
        this.adjustPictureSize();
        this.rotateImage();
        this.display_annotations();
      });
    } else {
      this.adjustPictureSize();
      this.rotateImage();
      this.display_annotations();
    }
  }

  componentDidMount() {
    this.setImageURL();
  }

  componentWillUnmount() {
    window.start_image_zoom = this.state.zoom;
    window.start_image_rotation = this.state.rotation;
  }

  setImageURL = () => {
    // Since HEIC and HEIF files can't be displayed, they must first be converted to JPEG.
    if (["image/heic", "image/heif"].includes(this.props.mime_type)) {
      // Returns a promise containing an object URL for a JPEG image converted from the HEIC/HEIF format.
      return fetch(this.props.url)
        .then(res => res.blob())
        .then(blob => heic2any({blob, toType: "image/jpeg"}))
        .then(conversionResult => URL.createObjectURL(conversionResult))
        .then(JPEGObjectURL => this.setState({url: JPEGObjectURL}));
    } else {
      return new Promise(() => this.setState({url: this.props.url}));
    }
  };

  display_annotations = () => {
    if (this.props.resultView && this.props.url) {
      this.ready_annotations();
      this.props.annotations.forEach(this.display_annotation);
    }
  };

  ready_annotations = () => {
    window.annotation_type = ANNOTATION_TYPES.IMAGE;

    $(".annotation_holder").remove();
    window.annotation_manager = new ImageAnnotationManager(!this.props.released_to_students);
    this.annotation_manager = window.annotation_manager;
  };

  display_annotation = annotation => {
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

    let originalImgH = document.getElementById("image_preview").height;
    let originalImgW = document.getElementById("image_preview").width;
    let imgW;
    let imgH;

    if (this.state.rotation === 90 || this.state.rotation === 270) {
      imgW = originalImgH;
      imgH = originalImgW;
    } else {
      imgW = originalImgW;
      imgH = originalImgH;
    }

    let midWidth = originalImgW / this.state.zoom / 2;
    let midHeight = originalImgH / this.state.zoom / 2;
    let midWidthRotated = imgW / 2;
    let midHeightRotated = imgH / 2;

    let xstart = annotation.x_range.start - midWidth;
    let xend = annotation.x_range.end - midWidth;
    let ystart = annotation.y_range.start - midHeight;
    let yend = annotation.y_range.end - midHeight;

    xstart *= this.state.zoom;
    xend *= this.state.zoom;
    yend *= this.state.zoom;
    ystart *= this.state.zoom;

    let topLeft = [xstart, ystart];
    let topRight = [xend, ystart];
    let bottomLeft = [xstart, yend];
    let bottomRight = [xend, yend];

    let rotatedTR = this.rotatedCoordinate(topRight, this.state.rotation);
    let rotatedTL = this.rotatedCoordinate(topLeft, this.state.rotation);
    let rotatedBL = this.rotatedCoordinate(bottomLeft, this.state.rotation);
    let rotatedBR = this.rotatedCoordinate(bottomRight, this.state.rotation);

    let corners;
    // index of coordinates in corners array matching position in plane
    //    1 - 2
    //    |
    //    0
    switch (this.state.rotation) {
      case 90:
        corners = [rotatedBR, rotatedBL, rotatedTL];
        break;
      case 180:
        corners = [rotatedTR, rotatedBR, rotatedBL];
        break;
      case 270:
        corners = [rotatedTL, rotatedTR, rotatedBR];
        break;
      default:
        corners = [rotatedBL, rotatedTL, rotatedTR];
    }

    this.annotation_manager.addAnnotation(
      annotation.annotation_text_id,
      content,
      {
        x_range: {
          start: Math.floor(midWidthRotated + corners[1][0]),
          end: Math.floor(midWidthRotated + corners[2][0]),
        },
        y_range: {
          start: Math.floor(midHeightRotated + corners[1][1]),
          end: Math.floor(midHeightRotated + corners[0][1]),
        },
      },
      annotation.id,
      annotation.is_remark
    );
  };

  rotatedCoordinate = (coordinate, rotation) => {
    if (rotation > 0) {
      return this.rotatedCoordinate([-coordinate[1], coordinate[0]], rotation - 90);
    }
    return coordinate;
  };

  addRotation = () => {
    this.setState(
      {
        rotation: this.state.rotation + 90 > 270 ? 0 : this.state.rotation + 90,
      },
      this.rotateImage
    );
  };

  adjustPictureSize = () => {
    let picture = document.getElementById("image_preview");
    picture.width = Math.floor(picture.naturalWidth * this.state.zoom);
  };

  zoomIn = () => {
    this.setState(prevState => {
      return {zoom: prevState.zoom + 0.1};
    }, this.adjustPictureSize);
  };

  zoomOut = () => {
    this.setState(prevState => {
      return {zoom: prevState.zoom - 0.1};
    }, this.adjustPictureSize);
  };

  rotateImage = () => {
    let picture = document.getElementById("image_preview");

    if (this.state.rotation > 0) {
      picture.addClass("rotate" + this.state.rotation.toString());
      picture.removeClass("rotate" + (this.state.rotation - 90).toString());
    } else {
      picture.removeClass("rotate270");
    }
  };

  render() {
    return (
      <React.Fragment>
        <p key={"image_toolbar"}>
          {I18n.t("results.current_rotation", {rotation: this.state.rotation})}
          <button onClick={this.addRotation} className={"inline-button"}>
            {I18n.t("results.rotate_image")}
          </button>
          {I18n.t("results.current_zoom_level", {
            level: Math.floor(this.state.zoom * 100),
          })}
          <button onClick={this.zoomIn} className={"inline-button"}>
            {I18n.t("results.zoom_in_image")}+
          </button>
          <button onClick={this.zoomOut} className={"inline-button"}>
            {I18n.t("results.zoom_out_image")}-
          </button>
        </p>
        <div id="image_container" key={"image_container"}>
          <div
            key="sel_box"
            id="sel_box"
            className="annotation-holder-active"
            style={{display: "none"}}
          />
          <img
            id="image_preview"
            src={this.state.url}
            data-zoom={this.state.zoom}
            className={this.props.released_to_students ? "" : "enable-annotations"}
            onLoad={() => {
              this.adjustPictureSize();
              this.rotateImage();
              this.display_annotations();
            }}
            alt={I18n.t("results.cant_display_image")}
          />
        </div>
      </React.Fragment>
    );
  }
}
