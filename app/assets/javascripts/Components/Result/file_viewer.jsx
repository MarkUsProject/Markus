import React from "react";

import {ImageViewer} from "./image_viewer";
import {TextViewer} from "./text_viewer";
import {PDFViewer} from "./pdf_viewer";
import {NotebookViewer} from "./notebook_viewer";
import {BinaryViewer} from "./binary_viewer";
import {URLViewer} from "./url_viewer";

export class FileViewer extends React.Component {
  state = {
    loading: false,
    errorMessage: null,
  };

  setLoading(loading) {
    this.setState({loading: loading});
  }

  setErrorMessage(errorMessage) {
    this.setState({errorMessage: errorMessage});
  }

  render() {
    const commonProps = {
      submission_file_id: this.props.selectedFile,
      annotations: this.props.annotations ? this.props.annotations : [],
      released_to_students: this.props.released_to_students,
      resultView: !!this.props.result_id,
      course_id: this.props.course_id,
      key: `${this.props.selectedFileType}-viewer`,
    };

    if (this.state.errorMessage) {
      return <p>{this.state.errorMessage}</p>;
    } else if (this.state.loading) {
      return I18n.t("working");
    } else if (this.props.selectedFileType === "image") {
      return <ImageViewer url={this.state.url} mime_type={this.props.mime_type} {...commonProps} />;
    } else if (this.props.selectedFileType === "pdf") {
      return (
        <PDFViewer
          url={this.state.url}
          annotationFocus={this.props.annotationFocus}
          {...commonProps}
        />
      );
    } else if (this.props.selectedFileType === "jupyter-notebook") {
      return (
        <NotebookViewer
          url={this.state.url}
          annotationFocus={this.props.annotationFocus}
          {...commonProps}
        />
      );
    } else if (this.props.selectedFileType === "binary") {
      return (
        <BinaryViewer
          url={this.state.url}
          content={this.state.content}
          getAnyway={() => this.set_submission_file(this.props.selectedFile, true)}
          {...commonProps}
        />
      );
    } else if (this.props.selectedFileType === "markusurl") {
      return <URLViewer externalUrl={this.state.content} {...commonProps} />;
    } else if (this.props.selectedFileType !== "") {
      return (
        <TextViewer
          url={this.props.selectedFileURL}
          type={this.props.selectedFileType}
          content={this.state.content}
          focusLine={this.props.focusLine}
          {...commonProps}
        />
      );
    } else {
      return "";
    }
  }
}
