import React from "react";
import {createRoot} from "react-dom/client";
import FileManager from "./markus_file_manager";
import SubmissionFileUploadModal from "./Modals/submission_file_upload_modal";
import SubmitUrlUploadModal from "./Modals/submission_url_submit_modal";
import {FileViewer} from "./Result/file_viewer";
import mime from "mime/lite";
import {flashMessage} from "../common/flash";

class SubmissionFileManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      files: [],
      showUploadModal: false,
      showURLModal: false,
      uploadTarget: undefined,
      viewFile: null,
      viewFileType: null,
      viewFileURL: null,
      onlyRequiredFiles: false,
      requiredFiles: [],
      maxFileSize: 0,
      numberOfMissingFiles: 0,
      uploadModalProgressVisible: false,
      uploadModalProgressPercentage: 0.0,
    };
  }

  static defaultProps = {
    fetchOnMount: true,
    readOnly: false,
    revision_identifier: undefined,
    starterFileChanged: false,
  };

  componentDidMount() {
    if (this.props.fetchOnMount) {
      this.fetchData();
    }
  }

  fetchData = () => {
    let data = {course_id: this.props.course_id, assignment_id: this.props.assignment_id};
    if (typeof this.props.grouping_id !== "undefined") {
      data.grouping_id = this.props.grouping_id;
    }
    if (typeof this.props.revision_identifier !== "undefined") {
      data.revision_identifier = this.props.revision_identifier;
    }

    fetch(Routes.populate_file_manager_course_assignment_submissions_path(data), {
      credentials: "same-origin",
      headers: {
        "content-type": "application/json",
      },
    })
      .then(data => data.json())
      .then(data =>
        this.setState({
          files: data.entries,
          viewFile: null,
          viewFileType: null,
          viewFileURL: null,
          onlyRequiredFiles: data.only_required_files,
          requiredFiles: data.required_files,
          maxFileSize: data.max_file_size,
          numberOfMissingFiles: data.number_of_missing_files,
        })
      );
  };

  // Update state when a new revision_identifier props is passed
  componentDidUpdate(oldProps) {
    if (oldProps.revision_identifier !== this.props.revision_identifier) {
      this.fetchData();
    }
  }

  handleCreateUrl = (url, url_text) => {
    this.setState({showURLModal: false});
    const data_to_upload = {
      new_url: url,
      url_text: url_text,
      path: "/" + (this.state.uploadTarget || ""),
    };
    if (this.props.grouping_id) {
      data_to_upload.grouping_id = this.props.grouping_id;
    }
    $.post({
      url: Routes.update_files_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: data_to_upload,
    })
      .then(typeof this.props.onChange === "function" ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleCreateFiles = (files, path, unzip, renameTo = "") => {
    if (
      !this.props.starterFileChanged ||
      confirm(I18n.t("assignments.starter_file.upload_confirmation"))
    ) {
      this.setState({uploadModalProgressVisible: true});

      const prefix = path || this.state.uploadTarget || "";
      let data = new FormData();
      if (!!renameTo && files.length === 1) {
        Array.from(files).forEach(f => data.append("new_files[]", f, renameTo));
      } else {
        Array.from(files).forEach(f => data.append("new_files[]", f, f.name));
      }
      data.append("path", "/" + prefix); // Server expects path with leading slash (TODO: fix that)
      if (this.props.grouping_id) {
        data.append("grouping_id", this.props.grouping_id);
      }
      data.append("unzip", unzip);

      $.post({
        url: Routes.update_files_course_assignment_submissions_path(
          this.props.course_id,
          this.props.assignment_id
        ),
        data: data,
        processData: false, // tell jQuery not to process the data
        contentType: false, // tell jQuery not to set contentType
        xhr: () => {
          const xhr = new XMLHttpRequest();

          xhr.upload.addEventListener(
            "progress",
            event => {
              if (event.lengthComputable) {
                this.setState({uploadModalProgressPercentage: (event.loaded / event.total) * 100});
              }
            },
            false
          );

          return xhr;
        },
      })
        .then(typeof this.props.onChange === "function" ? this.props.onChange : this.fetchData)
        .then(this.endAction)
        .fail(jqXHR => {
          if (jqXHR.getResponseHeader("x-message-error") == null) {
            flashMessage(I18n.t("upload_errors.generic"), "error");
          }
        })
        .always(() => {
          this.setState({
            showUploadModal: false,
            uploadTarget: undefined,
            uploadModalProgressVisible: false,
            uploadModalProgressPercentage: 0.0,
          });
        });
    }
  };

  handleDeleteFile = fileKeys => {
    if (!this.state.files.some(f => fileKeys.includes(f.key))) {
      return;
    }

    $.post({
      url: Routes.update_files_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        delete_files: fileKeys,
        grouping_id: this.props.grouping_id,
      },
    })
      .then(
        typeof this.props.onChange === "function"
          ? () =>
              this.setState(
                {viewFile: null, viewFileType: null, viewFileURL: null},
                this.props.onChange
              )
          : this.fetchData
      )
      .then(this.endAction);
  };

  handleCreateFolder = folderKey => {
    if (
      !this.props.starterFileChanged ||
      confirm(I18n.t("assignments.starter_file.upload_confirmation"))
    ) {
      $.post({
        url: Routes.update_files_course_assignment_submissions_path(
          this.props.course_id,
          this.props.assignment_id
        ),
        data: {
          new_folders: [folderKey],
          grouping_id: this.props.grouping_id,
        },
      })
        .then(typeof this.props.onChange === "function" ? this.props.onChange : this.fetchData)
        .then(this.endAction);
    }
  };

  handleDeleteFolder = folderKeys => {
    $.post({
      url: Routes.update_files_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        delete_folders: folderKeys,
        grouping_id: this.props.grouping_id,
      },
    })
      .then(typeof this.props.onChange === "function" ? this.props.onChange : this.fetchData)
      .then(this.endAction);
  };

  handleActionBarDeleteClick = event => {
    event.preventDefault();
    if (this.state.selection) {
      this.handleDeleteFile(this.state.selection);
    }
  };

  getDownloadAllURL = () => {
    return Routes.downloads_course_assignment_submissions_path(
      this.props.course_id,
      this.props.assignment_id,
      this.props.grouping_id,
      {
        revision_identifier: this.props.revision_identifier,
        grouping_id: this.props.grouping_id,
      }
    );
  };

  openUploadModal = uploadTarget => {
    this.setState({showUploadModal: true, uploadTarget: uploadTarget});
  };

  openSubmitURLModal = uploadTarget => {
    this.setState({showURLModal: true, uploadTarget: uploadTarget});
  };

  updateViewFile = item => {
    this.setState({
      viewFile: item.relativeKey,
      viewFileType: item.type,
      viewFileURL: item.url,
    });
  };

  renderFileViewer = () => {
    let heading;
    let content = "";
    if (this.state.viewFile !== null) {
      let withinSize =
        document.getElementById("content").getBoundingClientRect().width - 150 + "px";
      heading = this.state.viewFile;
      content = (
        <div
          id="codeviewer"
          className="text-viewer-container"
          style={{maxWidth: withinSize}}
          data-testid="file-preview-root"
        >
          <FileViewer
            assignment_id={this.props.assignment_id}
            grouping_id={this.props.grouping_id}
            revision_id={this.props.revision_identifier}
            selectedFile={this.state.viewFile}
            selectedFileType={this.state.viewFileType}
            selectedFileURL={this.state.viewFileURL}
            mime_type={mime.getType(this.state.viewFile)}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        </div>
      );
    } else {
      heading = I18n.t("submissions.student.select_file");
    }

    return (
      <fieldset style={{display: "flex", flexDirection: "column"}}>
        <legend>
          <span>{heading}</span>
        </legend>
        {content}
      </fieldset>
    );
  };

  renderRequiredFiles = () => {
    let requiredFilesBox;

    if (this.state.requiredFiles.length > 0) {
      requiredFilesBox = (
        <div>
          <h2>{I18n.t("activerecord.attributes.assignment.assignment_files")}</h2>
          <p>
            {this.state.numberOfMissingFiles === 0
              ? I18n.t("student.submission.all_files_submitted")
              : I18n.t("student.submission.missing_files", {file: this.state.numberOfMissingFiles})}
          </p>
          {this.state.requiredFiles.map(filename => {
            return (
              <p key={filename} className={"required-files-container"}>
                <input
                  className={"required-files-checkbox"}
                  type={"checkbox"}
                  disabled={true}
                  checked={this.state.files.some(element => element.key === filename)}
                  name={`required-file-${filename}`}
                  id={`required-file-${filename}`}
                />
                <label htmlFor={`required-file-${filename}`}>
                  &nbsp; {filename}
                  {this.state.files.some(element => element.key === filename) ? (
                    ""
                  ) : (
                    <strong>&nbsp; {I18n.t("submissions.student.missing")}</strong>
                  )}
                </label>
              </p>
            );
          })}
        </div>
      );
    } else {
      requiredFilesBox = "";
    }
    return (
      <div className={"pane-wrapper small-bottom-margin"}>
        <div className={"pane"}>
          {requiredFilesBox}
          {this.state.onlyRequiredFiles ? (
            <p>{I18n.t("submissions.student.only_required_files")}</p>
          ) : (
            ""
          )}
          <p>
            {I18n.t("submissions.student.maximum_file_size", {file_size: this.state.maxFileSize})}
          </p>
        </div>
      </div>
    );
  };

  render() {
    return (
      <div>
        {this.renderRequiredFiles()}
        <FileManager
          files={this.state.files}
          noFilesMessage={I18n.t("submissions.no_files_available")}
          readOnly={this.props.readOnly}
          onDeleteFile={this.props.readOnly ? undefined : this.handleDeleteFile}
          onCreateFiles={this.props.readOnly ? undefined : this.handleCreateFiles}
          onCreateFolder={this.props.readOnly ? undefined : this.handleCreateFolder}
          onRenameFolder={
            !this.props.readOnly && typeof this.handleCreateFolder === "function"
              ? () => {}
              : undefined
          }
          onDeleteFolder={this.props.readOnly ? undefined : this.handleDeleteFolder}
          downloadAllURL={this.getDownloadAllURL()}
          onActionBarAddFileClick={this.props.readOnly ? undefined : this.openUploadModal}
          disableActions={{
            rename: true,
            addFolder: !this.props.enableSubdirs,
            deleteFolder: !this.props.enableSubdirs,
          }}
          onSelectFile={this.updateViewFile}
          enableUrlSubmit={this.props.enableUrlSubmit}
          onActionBarSubmitURLClick={this.props.readOnly ? undefined : this.openSubmitURLModal}
          isSubmittingItems={true}
        />
        <SubmissionFileUploadModal
          isOpen={this.state.showUploadModal}
          onRequestClose={() => this.setState({showUploadModal: false, uploadTarget: undefined})}
          onSubmit={this.handleCreateFiles}
          progressVisible={this.state.uploadModalProgressVisible}
          progressPercentage={this.state.uploadModalProgressPercentage}
          onlyRequiredFiles={this.state.onlyRequiredFiles}
          requiredFiles={this.state.requiredFiles}
          uploadTarget={this.state.uploadTarget}
        />
        <SubmitUrlUploadModal
          isOpen={this.state.showURLModal}
          onRequestClose={() => this.setState({showURLModal: false})}
          onSubmit={this.handleCreateUrl}
        />
        {this.renderFileViewer()}
      </div>
    );
  }
}

export function makeSubmissionFileManager(elem, props) {
  const root = createRoot(elem);
  root.render(<SubmissionFileManager {...props} />);
}

export {SubmissionFileManager};
