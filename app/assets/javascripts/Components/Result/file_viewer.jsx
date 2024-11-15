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

  mountedRef = React.createRef();

  setLoading = loading => {
    if (this.mountedRef.current) {
      this.setState({loading: loading});
    }
  };

  componentDidMount() {
    this.mountedRef.current = true;
  }

  componentWillUnmount() {
    this.mountedRef.current = false;
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
    };

    if (this.props.selectedFileType === "image") {
      return <ImageViewer mime_type={this.props.mime_type} {...commonProps} />;
    } else if (this.props.selectedFileType === "pdf") {
      return <PDFViewer annotationFocus={this.props.annotationFocus} {...commonProps} />;
    } else if (this.props.selectedFileType === "jupyter-notebook") {
      return <NotebookViewer annotationFocus={this.props.annotationFocus} {...commonProps} />;
    } else if (this.props.selectedFileType === "binary") {
      return (
        <BinaryViewer
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
          type={this.props.selectedFileType}
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

    return (
      <React.Fragment>
        <div style={{display: this.state.loading ? "none" : "block"}}>{viewer}</div>
        {this.state.loading && <p>{I18n.t("working")}</p>}
      </React.Fragment>
    );
  }
}
