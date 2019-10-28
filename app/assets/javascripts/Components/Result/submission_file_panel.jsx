import React from 'react';
import ReactDOM from 'react-dom';

import { AnnotationManager } from './annotation_manager';
import { FileViewer } from './file_viewer';
import { DownloadSubmissionModal } from './download_submission_modal';


export class SubmissionFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: null,
      focusLine: null
    };
    this.submissionFileViewer = React.createRef();
  }

  componentDidMount() {
    // TODO: remove this binding.
    window.submissionFilePanel = this;

    this.modalDownload = new ModalMarkus('#download_dialog');
    if (localStorage.getItem('assignment_id') !== String(this.props.assignment_id)) {
      localStorage.removeItem('file');
    }
    localStorage.setItem('assignment_id', this.props.assignment_id);

    // TODO: Incorporate DownloadSubmissionModal as true child of this component.
    if (this.props.canDownload) {
      ReactDOM.render(
        <DownloadSubmissionModal
          fileData={this.props.fileData}
          initialFile={this.state.selectedFile}
          downloadURL={Routes.download_assignment_submission_result_url(
            this.props.assignment_id, this.props.submission_id, this.props.result_id)}
        />,
        document.getElementById('download_dialog_body')
      );
    }
    const selectedFile = this.getFirstFile(this.props.fileData);
    this.setState({selectedFile});
  }

  componentDidUpdate(prevProps) {
    if (this.props.canDownload) {
      ReactDOM.render(
        <DownloadSubmissionModal
          fileData={this.props.fileData}
          initialFile={this.state.selectedFile}
          downloadURL={Routes.download_assignment_submission_result_url(
            this.props.assignment_id, this.props.submission_id, this.props.result_id)}
        />,
        document.getElementById('download_dialog_body')
      );
    }

    if (prevProps.loading && !this.props.loading) {
      let selectedFile = [];
      const stored_file = localStorage.getItem('file');
      const stored_assignment = localStorage.getItem('assignment_id');
      if (!this.state.student_view && stored_assignment === this.props.assignment_id.toString() && stored_file) {
        let filepath = stored_file.split('/');
        let filename = filepath.pop();
        selectedFile = [stored_file, this.getNamedFileId(this.props.fileData, filepath, filename)];
      }
      if (!selectedFile[1]) {
        localStorage.removeItem('file');
        selectedFile = this.getFirstFile(this.props.fileData);
      }
      this.setState({selectedFile});
    }
  }

  getNamedFileId = (fileData, path, filename) => {
    if (!!path.length) {
      let dir = path.shift();
      if (fileData.directories.hasOwnProperty(dir)) {
        return this.getNamedFileId(fileData.directories[dir], path, filename)
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

  getFirstFile = (fileData) => {
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

  selectFile = (file, id, focusLine) => {
    this.setState({selectedFile: [file, id], focusLine: focusLine});
    localStorage.setItem('file', file);
  };

  // Download the currently-selected file.
  downloadFile = () => {
    this.modalDownload.open();
  };

  render() {
    let submission_file_id, visibleAnnotations;
    if (this.state.selectedFile === null) {
      submission_file_id = null;
      visibleAnnotations = [];
    } else {
      submission_file_id = this.state.selectedFile[1];
      visibleAnnotations = this.props.annotations.filter(a => a.submission_file_id === submission_file_id);
    }
    return [
        <div key='sel_box' id='sel_box'/>,
        <div key='annotation_menu' id='annotation_menu'>
          <FileSelector
            fileData={this.props.fileData}
            onSelectFile={this.selectFile}
            selectedFile={this.state.selectedFile}
          />
          {this.props.canDownload &&
            <button onClick={() => this.modalDownload.open()}>
              {I18n.t('download')}
            </button>}
          <div id='annotation_options'>
            {this.props.show_annotation_manager &&
             <AnnotationManager
               categories={this.props.annotation_categories}
               newAnnotation={this.props.newAnnotation}
               addExistingAnnotation={this.props.addExistingAnnotation}
             />
            }
          </div>
        </div>,
        <div key='codeviewer' id='codeviewer'>
          <FileViewer
            ref={this.submissionFileViewer}
            assignment_id={this.props.assignment_id}
            submission_id={this.props.submission_id}
            result_id={this.props.result_id}
            selectedFile={submission_file_id}
            annotations={visibleAnnotations}
            focusLine={this.state.focusLine}
            released_to_students={this.props.released_to_students}
          />
        </div>
    ];
  }
}


// Component for the file selector.
export class FileSelector extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      expanded: null
    }
  }

  // Convert a nested hash into a nested <ul>.
  hashToHTMLList = (hash, expanded) => {
    let dirs = [];
    let newExpanded, displayStyle;
    if (expanded === null) {
      newExpanded = null;
      displayStyle = 'none';
    } else if (hash['name'] === '') {
      newExpanded = expanded;
      displayStyle = 'block'
    } else {
      newExpanded = expanded.slice(1);
      displayStyle = hash['name'] === expanded[0] ? 'block' : 'none';
    }

    for (let d in hash['directories']) {
      if (hash['directories'].hasOwnProperty(d)) {
        let dir = hash['directories'][d];
        dirs.push(
          <li className='nested-submenu' key={dir.path.join('/')}>
            <a key={`${dir.path.join('/')}-a`} onClick={(e) => this.selectDirectory(e, dir.path)}>
              <strong>{dir.name}</strong>
            </a>
            {this.hashToHTMLList(dir, newExpanded)}
          </li>
        );
      }
    }

    return (
      <ul className='nested-folder' style={{display: displayStyle}}>
        {dirs}
        {hash['files'].map(f => {
          const [name, id] = f;
          const fullPath = hash.path.concat([name]).join('/');
          return (<li className='file_item' key={fullPath}>
            <a
              key={`${fullPath}-a`}
              onClick={(e) => this.selectFile(e, fullPath, id)}>
              {f[0]}
            </a>
          </li>)
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

  expandFileSelector = (path) => {
    this.setState({expanded: path});
  };

  render() {
    const fileSelector = this.hashToHTMLList(this.props.fileData, this.state.expanded);
    let arrow, expand;
    if (this.state.expanded !== null) {
      arrow = <span className='arrow-up' />;
      expand = null;
    } else {
      arrow = <span className='arrow-down' />;
      expand = [];
    }
    let selectorLabel;
    if (!this.props.fileData.files.length && !Object.keys(this.props.fileData.directories).length) {
      selectorLabel = I18n.t('submissions.no_files_available');
    } else if (this.props.selectedFile !== null) {
      selectorLabel = this.props.selectedFile[0];
    } else {
      selectorLabel = '';
    }

    return (
      <div className='file_selector'>
        <div
          className='dropdown'
          onClick={(e) => {
            e.stopPropagation();
            this.expandFileSelector(expand);
          }}
          onBlur={() => this.expandFileSelector(null)}
          tabIndex={-1}
        >
          <a>{selectorLabel}</a>
          {arrow}
          {this.state.expanded &&
           <div>
             {fileSelector}
           </div>}
        </div>
      </div>
    );
  }
}
