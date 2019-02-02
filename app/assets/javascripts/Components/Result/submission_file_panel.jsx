import React from 'react';

import { AnnotationManager } from './annotation_manager';
import { FileViewer } from './file_viewer';


export class SubmissionFilePanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: null,
      fileContents: null,
      fileType: null,
      fileData: {files: [], directories: {}, name: ''},
      expanded: null
    };
    this.submissionFileViewer = React.createRef();
  }

  componentDidMount() {
    this.fetchFileList();
    this.modalDownload = new ModalMarkus('#download_dialog');
    if (localStorage.getItem('assignment_id') !== this.props.assignment_id) {
      localStorage.removeItem('file');
      localStorage.removeItem('file_id');
    }
    localStorage.setItem('assignment_id', this.props.assignment_id);
  }

  fetchFileList = () => {
    $.get({
      url: Routes.submission_files_assignment_submission_path(
        this.props.assignment_id, this.props.submission_id
      ),
      dataType: 'json'
    }).then(res => {
      let fileData = {files: [], directories: {}, name: '', path: []};
      res.forEach(({id, filename, path}) => {
        // Use .slice(1) to remove the Assignment repository name.
        let segments = path.split('/').concat(filename).slice(1);
        let currHash = fileData;
        segments.forEach((segment, i) => {
          if (i === segments.length - 1) {
            currHash.files.push([segment, id]);
          } else if (currHash.directories.hasOwnProperty(segment)) {
            currHash = currHash.directories[segment];
          } else {
            currHash.directories[segment] = {
              files: [], directories: {}, name: segment,
              path: segments.slice(0, i + 1)
            };
            currHash = currHash.directories[segment];
          }
        })
      });
      const firstFile = this.getFirstFile(fileData);
      this.setState({fileData: fileData, selectedFile: firstFile});
    });
  };

  getFirstFile = (fileData) => {
    if (!this.state.student_view &&
        localStorage.getItem('assignment_id') === this.props.assignment_id.toString() &&
        localStorage.getItem('file')) {
      return [localStorage.getItem('file'), localStorage.getItem('file_id')];
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
            <a onClick={(e) => {
              e.stopPropagation();
              this.expandFileSelector(dir.path);
            }}><strong>{dir.name}</strong></a>
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
            <a onClick={(e) => {
              e.stopPropagation();
              this.selectFile(fullPath, id);
            }}>
              {f[0]}
            </a>
          </li>)
        })}
      </ul>
    );
  };

  expandFileSelector = (path) => {
    this.setState({expanded: path});
  };

  selectFile = (file, id, focus_line) => {
    this.setState({selectedFile: [file, id]});
    localStorage.setItem('file', file);
    localStorage.setItem('file_id', id)
  };

  selectFileAndFocus = (id, focus_line) => {
    if (this.state.selectedFile !== null && this.state.selectedFile[1] === id) {
      focus_source_code_line(focus_line);
    } else {
      let fullPath = this.findFileById(id, this.state.fileData);
      if (fullPath !== null) {
        this.selectFile(fullPath, id, focus_line);
      }
    }
  };

  findFileById = (id, fileData) => {
    for (let i = 0; i < fileData.files.length; i++) {
      if (fileData.files[i][1] === id) {
        return fileData.path.length > 0 ? fileData.path + '/' + fileData.files[i][0] : fileData.files[i][0];
      }
    }

    for (let dir in fileData.directories) {
      if (fileData.directories.hasOwnProperty(dir)) {
        let newDir = this.findFileById(id, dir);
        if (newDir !== null) {
          return newDir;
        }
      }
    }
    return null;
  };

  // Download the currently-selected file.
  downloadFile = () => {
    this.modalDownload.open();
  };

  render() {
    const fileSelector = this.hashToHTMLList(this.state.fileData, this.state.expanded);
    let arrow, expand;
    if (this.state.expanded !== null) {
      arrow = <span className='arrow_up' />;
      expand = null;
    } else {
      arrow = <span className='arrow_down' />;
      expand = [];
    }
    let selectorLabel;
    if (this.state.fileData.files.length === 0 && this.state.fileData.directories.length === 0) {
      selectorLabel = I18n.t('submissions.no_files_available');
    } else if (this.state.selectedFile !== null) {
      selectorLabel = this.state.selectedFile[0];
    } else {
      selectorLabel = '';
    }

    const submission_file_id = this.state.selectedFile === null ? null : this.state.selectedFile[1];

    return (
      <div>
        <div id='sel_box'/>
        <div id='annotation_menu'>
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
          />
        </div>
      </div>
    );
  }
}
