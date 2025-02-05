import React from "react";
import {FileViewer} from "./file_viewer";
import mime from "mime/lite";
import {ResultContext} from "./result_context";

export class FeedbackFilePanel extends React.Component {
  static contextType = ResultContext;

  constructor(props) {
    super(props);
    if (props.loading) {
      this.state = {selectedFile: null};
    } else {
      this.state = {
        selectedFile: props.feedbackFiles.length > 0 ? props.feedbackFiles[0].id : null,
      };
    }
  }

  static getDerivedStateFromProps(props, state) {
    if (props.loading && state.selectedFile !== null) {
      return {selectedFile: null};
    } else if (!props.feedbackFiles.find(file => file.id === state.selectedFile)) {
      return {
        selectedFile: props.feedbackFiles.length > 0 ? props.feedbackFiles[0].id : null,
      };
    } else {
      return null;
    }
  }

  updateSelectedFile = event => {
    this.setState({selectedFile: parseInt(event.target.value, 10)});
  };

  render() {
    if (this.props.loading) {
      return "";
    }

    let feedbackSelector;
    if (this.props.feedbackFiles) {
      feedbackSelector = (
        <select
          onChange={this.updateSelectedFile}
          value={this.state.selectedFile}
          className={"dropdown"}
        >
          {this.props.feedbackFiles.map(file => (
            <option value={file.id} key={file.id}>
              {file.filename}
            </option>
          ))}
        </select>
      );
    } else {
      feedbackSelector = (
        <select onChange={this.updateSelectedFile} className={"dropdown"}>
          <option value="">{I18n.t("results.no_feedback_files")}</option>
        </select>
      );
    }

    let url, file_obj;
    let download_feedback_file = (
      <a className="button disabled" href="#">
        {I18n.t("download")}
      </a>
    );
    if (this.state.selectedFile !== null) {
      url = Routes.course_feedback_file_path(this.context.course_id, this.state.selectedFile);
      file_obj = this.props.feedbackFiles.find(file => file.id === this.state.selectedFile);
      download_feedback_file = (
        <a className="button" href={url} download>
          {I18n.t("download")}
        </a>
      );
    }

    return (
      <React.Fragment>
        <div className="react-tabs-panel-action-bar" key={"feedback-file-actionbar"}>
          {feedbackSelector}
          {download_feedback_file}
        </div>
        <div
          id="feedback_file_content"
          className="text-viewer-container"
          key={"feedback-file-view"}
        >
          <FileViewer
            assignment_id={this.context.assignment_id}
            submission_id={this.context.submission_id}
            selectedFile={file_obj.filename}
            selectedFileURL={url}
            mime_type={mime.getType(file_obj.filename)}
            selectedFileType={file_obj.type}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        </div>
      </React.Fragment>
    );
  }
}
