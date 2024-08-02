import React from "react";
import ReactDOM from "react-dom";

import {AnnotationManager} from "./annotation_manager";
import {FileViewer} from "./file_viewer";
import {DownloadSubmissionModal} from "./download_submission_modal";
import mime from "mime/lite";

export class SubmissionFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: null,
      focusLine: null,
      annotationFocus: undefined,
      selectedFileType: null,
      visibleAnnotations: [],
    };
    this.submissionFileViewer = React.createRef();
  }

  componentDidMount() {
    // TODO: remove this binding.
    window.submissionFilePanel = this;

    this.modalDownload = new ModalMarkus("#download_dialog");
    this.refreshSelectedFile();
  }

  componentDidUpdate(prevProps) {
    if (
      prevProps.result_id !== this.props.result_id ||
      (prevProps.loading && !this.props.loading)
    ) {
      this.refreshSelectedFile();
    } else if (
      prevProps.annotations !== this.props.annotations &&
      this.state.selectedFile !== null
    ) {
      const submission_file_id = this.state.selectedFile[1];
      const visibleAnnotations = this.props.annotations.filter(
        a => a.submission_file_id === submission_file_id
      );
      this.setState({visibleAnnotations});
    }
  }

  handleFileTypeUpdate = newType => {
    this.setState({
      selectedFileType: newType,
    });
  };

  refreshSelectedFile = () => {
    if (localStorage.getItem("assignment_id") !== String(this.props.assignment_id)) {
      localStorage.removeItem("file");
    }
    localStorage.setItem("assignment_id", this.props.assignment_id);

    let selectedFile = [];
    const stored_file = localStorage.getItem("file");
    if (!this.state.student_view && stored_file) {
      let filepath = stored_file.split("/");
      let filename = filepath.pop();
      selectedFile = [stored_file, this.getNamedFileId(this.props.fileData, filepath, filename)];
    }
    if (!selectedFile[1]) {
      if (
        this.props.fileData.files.length > 0 ||
        Object.keys(this.props.fileData.directories).length > 0
      ) {
        // Remove invalid storage entry if this.props.fileData has data and the file was not found.
        localStorage.removeItem("file");
      }
      selectedFile = this.getFirstFile(this.props.fileData);
    }

    let visibleAnnotations;
    if (selectedFile === null) {
      visibleAnnotations = [];
    } else {
      const submission_file_id = selectedFile[1];
      visibleAnnotations = this.props.annotations.filter(
        a => a.submission_file_id === submission_file_id
      );
    }
    this.setState({selectedFile, visibleAnnotations});

    // TODO: Incorporate DownloadSubmissionModal as true child of this component.
    if (this.props.canDownload) {
      ReactDOM.render(
        <DownloadSubmissionModal
          fileData={this.props.fileData}
          initialFile={selectedFile}
          downloadURL={Routes.download_file_course_assignment_submission_url(
            this.props.course_id,
            this.props.assignment_id,
            this.props.submission_id
          )}
        />,
        document.getElementById("download_dialog_body")
      );
    }
  };

  getNamedFileId = (fileData, path, filename) => {
    if (!!path.length) {
      let dir = path.shift();
      if (fileData.directories.hasOwnProperty(dir)) {
        return this.getNamedFileId(fileData.directories[dir], path, filename);
      }
    } else {
      for (let file_data of fileData.files) {
        if (file_data[0] === filename) {
          return file_data[1];
        }
      }
    }
    return null;
  };

  getFirstFile = fileData => {
    if (fileData.files.length > 0) {
      return fileData.files[0];
    }
    for (let dir in fileData.directories) {
      if (fileData.directories.hasOwnProperty(dir)) {
        let f = this.getFirstFile(fileData.directories[dir]);
        if (f !== null) {
          f[0] = `${dir}/${f[0]}`;
          return f;
        }
      }
    }
    return null;
  };

  selectFile = (file, id, focusLine, annotationFocus) => {
    this.setState({
      selectedFile: [file, id],
      focusLine: focusLine,
      annotationFocus: annotationFocus,
      visibleAnnotations: this.props.annotations.filter(a => a.submission_file_id === id),
    });
    localStorage.setItem("file", file);
  };

  // Download the currently-selected file.
  downloadFile = () => {
    this.modalDownload.open();
  };

  render() {
    let submission_file_id, submission_file_mime_type;
    if (this.state.selectedFile === null) {
      submission_file_id = null;
      submission_file_mime_type = null;
    } else {
      submission_file_id = this.state.selectedFile[1];
      submission_file_mime_type = mime.getType(this.state.selectedFile[0]);
    }
    return (
      <React.Fragment>
        <div key="annotation_menu" className="react-tabs-panel-action-bar">
          <FileSelector
            fileData={this.props.fileData}
            onSelectFile={this.selectFile}
            selectedFile={this.state.selectedFile}
            course_id={this.props.course_id}
          />
          {this.props.canDownload && (
            <button onClick={() => this.modalDownload.open()}>{I18n.t("download")}</button>
          )}
          {this.props.show_annotation_manager && this.state.selectedFileType !== "markusurl" && (
            <AnnotationManager
              categories={this.props.annotation_categories}
              newAnnotation={this.props.newAnnotation}
              addExistingAnnotation={this.props.addExistingAnnotation}
              course_id={this.props.course_id}
            />
          )}
        </div>
        <div key="codeviewer" id="codeviewer">
          <FileViewer
            ref={this.submissionFileViewer}
            handleFileTypeUpdate={this.handleFileTypeUpdate}
            assignment_id={this.props.assignment_id}
            submission_id={this.props.submission_id}
            mime_type={submission_file_mime_type}
            result_id={this.props.result_id}
            selectedFile={submission_file_id}
            annotations={this.state.visibleAnnotations}
            focusLine={this.state.focusLine}
            annotationFocus={this.state.annotationFocus}
            released_to_students={this.props.released_to_students}
            course_id={this.props.course_id}
          />
        </div>
      </React.Fragment>
    );
  }
}

// Component for the file selector.
export class FileSelector extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: null,
    };
  }

  // Convert a nested hash into a nested <ul>.
  hashToHTMLList = (hash, expanded) => {
    let dirs = [];
    let newExpanded, displayStyle;
    if (expanded === null) {
      newExpanded = null;
      displayStyle = "none";
    } else if (hash["name"] === "") {
      newExpanded = expanded;
      displayStyle = "block";
    } else {
      newExpanded = expanded.slice(1);
      displayStyle = hash["name"] === expanded[0] ? "block" : "none";
    }

    for (let d in hash["directories"]) {
      if (hash["directories"].hasOwnProperty(d)) {
        let dir = hash["directories"][d];
        dirs.push(
          <li
            className="nested-submenu"
            key={dir.path.join("/")}
            onClick={e => this.selectDirectory(e, dir.path)}
          >
            <a key={`${dir.path.join("/")}-a`}>{dir.name}</a>
            {this.hashToHTMLList(dir, newExpanded)}
          </li>
        );
      }
    }

    return (
      <ul className="nested-folder" style={{display: displayStyle}}>
        {dirs}
        {hash["files"].map(f => {
          const [name, id] = f;
          const fullPath = hash.path.concat([name]).join("/");
          return (
            <li
              className="file_item"
              key={fullPath}
              onClick={e => this.selectFile(e, fullPath, id)}
            >
              <a key={`${fullPath}-a`}>{f[0]}</a>
            </li>
          );
        })}
      </ul>
    );
  };

  selectFile = (e, fullPath, id) => {
    e.stopPropagation();
    this.props.onSelectFile(fullPath, id);
    this.setState({expanded: null});
  };

  selectDirectory = (e, path) => {
    e.stopPropagation();
    this.setState({expanded: path});
  };

  expandFileSelector = path => {
    this.setState({expanded: path});
  };

  render() {
    const fileSelector = this.hashToHTMLList(this.props.fileData, this.state.expanded);
    let arrow, expand;
    if (this.state.expanded !== null) {
      arrow = <span className="arrow-up" />;
      expand = null;
    } else {
      arrow = <span className="arrow-down" />;
      expand = [];
    }
    let selectorLabel;
    if (!this.props.fileData.files.length && !Object.keys(this.props.fileData.directories).length) {
      selectorLabel = I18n.t("submissions.no_files_available");
    } else if (this.props.selectedFile !== null) {
      selectorLabel = this.props.selectedFile[0];
    } else {
      selectorLabel = "";
    }

    return (
      <div
        className="dropdown"
        onClick={e => {
          e.stopPropagation();
          this.expandFileSelector(expand);
        }}
        onBlur={() => this.expandFileSelector(null)}
        tabIndex={-1}
      >
        <a>{selectorLabel}</a>
        {arrow}
        {this.state.expanded && <div>{fileSelector}</div>}
      </div>
    );
  }
}
