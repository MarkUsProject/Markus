import React from 'react';

import { AnnotationManager } from './annotation_manager';
import { FileViewer } from './file_viewer';


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

    const selectedFile = this.getFirstFile(this.props.fileData);
    this.setState({selectedFile});

    this.modalDownload = new ModalMarkus('#download_dialog');
    if (localStorage.getItem('assignment_id') !== this.props.assignment_id) {
      localStorage.removeItem('file');
      localStorage.removeItem('file_id');
    }
    localStorage.setItem('assignment_id', this.props.assignment_id);
  }

  getFirstFile = (fileData) => {
    if (!this.state.student_view &&
        localStorage.getItem('assignment_id') === this.props.assignment_id.toString() &&
        localStorage.getItem('file')) {
      return [localStorage.getItem('file'), parseInt(localStorage.getItem('file_id'), 10)];
    }

    if (fileData.files.length > 0) {
      return fileData.files[0];
    }
    for (let dir in fileData.directories) {
      if (fileData.directories.hasOwnProperty(dir)) {
        let f = this.getFirstFile(dir);
        if (f !== null) {
          return f;
        }
      }
    }
    return null;
  };

  selectFile = (file, id, focusLine) => {
    this.setState({selectedFile: [file, id], focusLine: focusLine});
    localStorage.setItem('file', file);
    localStorage.setItem('file_id', id)
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
    return (
      <div>
        <div id='sel_box'/>
        <div id='annotation_menu'>
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
               assignment_id={this.props.assignment_id}
               submission_id={this.props.submission_id}
               result_id={this.props.result_id}
               submission_file_id={submission_file_id}
               categories={this.props.annotation_categories}
               newAnnotation={this.props.newAnnotation}
               addExistingAnnotation={this.props.addExistingAnnotation}
             />
            }
          </div>
        </div>
        <div id='codeviewer' className='flex-col'>
          <FileViewer
            ref={this.submissionFileViewer}
            assignment_id={this.props.assignment_id}
            submission_id={this.props.submission_id}
            result_id={this.props.result_id}
            selectedFile={submission_file_id}
            annotations={visibleAnnotations}
            focusLine={this.state.focusLine}
          />
        </div>
      </div>
    );
  }
}


// Component for the file selector.
class FileSelector extends React.Component {
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
            <a onClick={(e) => this.selectDirectory(e, dir.path)}>
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
            <a onClick={(e) => this.selectFile(e, fullPath, id)}>
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
      arrow = <span className='arrow_up' />;
      expand = null;
    } else {
      arrow = <span className='arrow_down' />;
      expand = [];
    }
    let selectorLabel;
    if (this.props.fileData.files.length === 0 && this.props.fileData.directories.length === 0) {
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
          onMouseLeave={() => this.expandFileSelector(null)}
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
