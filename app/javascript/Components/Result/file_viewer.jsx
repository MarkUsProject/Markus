import React from "react";

import {ImageViewer} from "./image_viewer";
import {TextViewer} from "./text_viewer";
import {PDFViewer} from "./pdf_viewer";
import {HTMLViewer} from "./html_viewer";
import {BinaryViewer} from "./binary_viewer";
import {URLViewer} from "./url_viewer";

export class FileViewer extends React.Component {
  state = {
    loading: false,
    errorMessage: null,
  };

  mounted = false;

  setLoading = loading => {
    if (this.mounted) {
      this.setState({loading: loading});
    }
  };

  setErrorMessage = message => {
    if (this.mounted) {
      this.setState({errorMessage: message});
    }
  };

  componentDidMount() {
    this.mounted = true;
  }

  componentWillUnmount() {
    this.mounted = false;
  }

  componentDidUpdate(prevProps, prevState, snapshot) {
    if (this.props !== prevProps) {
      this.setState({
        loading: false,
        errorMessage: null,
      });
    }
  }

  getViewer() {
    const commonProps = {
      submission_file_id: this.props.selectedFile,
      annotations: this.props.annotations ? this.props.annotations : [],
      released_to_students: this.props.released_to_students,
      resultView: !!this.props.result_id,
      course_id: this.props.course_id,
      key: `${this.props.selectedFileType}-viewer`,
      url: this.props.selectedFileURL,
      setLoadingCallback: this.setLoading,
      setErrorMessageCallback: this.setErrorMessage,
    };

    if (this.props.mime_type === "application/zip") {
      // Prevent previewing zip files
      return <p>{I18n.t("files.cannot_preview")}</p>;
    } else if (this.props.selectedFileType === "image") {
      return <ImageViewer mime_type={this.props.mime_type} {...commonProps} />;
    } else if (this.props.selectedFileType === "pdf") {
      return <PDFViewer annotationFocus={this.props.annotationFocus} {...commonProps} />;
    } else if (
      this.props.selectedFileType === "jupyter-notebook" ||
      (this.props.selectedFileType === "rmarkdown" && this.props.rmd_convert_enabled)
    ) {
      return <HTMLViewer annotationFocus={this.props.annotationFocus} {...commonProps} />;
    } else if (this.props.selectedFileType === "binary") {
      return <BinaryViewer {...commonProps} />;
    } else if (this.props.selectedFileType === "markusurl") {
      return <URLViewer {...commonProps} />;
    } else if (this.props.selectedFileType !== "") {
      return (
        <TextViewer
          type={
            this.props.selectedFileType === "rmarkdown" ? "markdown" : this.props.selectedFileType
          }
          focusLine={this.props.focusLine}
          {...commonProps}
        />
      );
    } else {
      return "";
    }
  }

  render() {
    const viewer = this.getViewer();
    const outerDivStyle = {
      display: this.state.loading || this.state.errorMessage ? "none" : "block",
      height: "100%",
    };
    return (
      <React.Fragment>
        <div style={outerDivStyle}>{viewer}</div>
        {this.state.errorMessage && <p>{this.state.errorMessage}</p>}
        {this.state.loading && !this.state.errorMessage && <p>{I18n.t("working")}</p>}
      </React.Fragment>
    );
  }
}
