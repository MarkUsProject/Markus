import React from 'react';
import heic2any from 'heic2any';

import {ImageViewer} from './image_viewer'
import {TextViewer} from './text_viewer'
import {PDFViewer} from './pdf_viewer';
import {JupyterNotebookViewer} from "./jupyter_notebook_viewer";
import {BinaryViewer} from "./binary_viewer";


export class FileViewer extends React.Component {
  // this.props.result_id is used as a flag for the component to
  // know whether it is displaying within the result view.

  constructor(props) {
    super(props);
    this.state = {
      content: '',
      type: '',
      url: '',
      loading: true
    };
  }

  componentDidMount() {
    if (!this.props.result_id || this.props.selectedFile !== null) {
      this.set_submission_file(this.props.selectedFile);
    } else {
      this.setState({loading: false})
    }
  }

  // Manually manage a change of selectedFile, as this requires fetching new file data.
  shouldComponentUpdate(nextProps) {
    if (!!this.props.result_id && this.props.selectedFile !== nextProps.selectedFile) {
      this.set_submission_file(nextProps.selectedFile);
      return false;
    } else {
      return true;
    }
  }

  componentDidUpdate(prevProps) {
    if (!this.props.result_id && prevProps.selectedFile !== this.props.selectedFile) {
      this.set_submission_file(null);
    }
  }

  setFileUrl = (submission_file_id) => {
    let url;
    if (!!this.props.selectedFileURL) { // Use file URL if defined
      url = this.props.selectedFileURL;
    } else { // Otherwise get submission file data
      url = Routes.download_assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id,
        {
          select_file_id: submission_file_id,
          show_in_browser: true,
          from_codeviewer: true,
        }
      );
    }
    if (['image/heic', 'image/heif'].includes(this.props.mime_type)) {
      fetch(url)
        .then((res) => res.blob())
        .then((blob) => heic2any({blob, toType:"image/jpeg"}))
        .then((conversionResult) => {this.setState({url: URL.createObjectURL(conversionResult), loading: false})})
    } else {
      this.setState({url: url, loading: false});
    }
  };

  /*
   * Update the contents being displayed with the given submission file id.
   */
  set_submission_file = (submission_file_id, force_text) => {
    if (!this.props.result_id && this.props.selectedFile === null) {
      this.setState({loading: false, type: null});
      return;
    }
    force_text = !!force_text;

    // TODO: is this the right spot to remove these? Should it be done earlier?
    $('.annotation_text_display').each(function() {
      this.remove();
    });

    this.setState({loading: true, url: null}, () => {
      if (!this.props.selectedFileURL) {
          fetch(Routes.get_file_assignment_submission_path(
            this.props.assignment_id,
            this.props.submission_id,
            {submission_file_id: submission_file_id, force_text: force_text}),
            {credentials: 'include'})
            .then(res => res.json())
            .then(body => {
              if (body.type === 'image' || body.type === 'pdf') {
                this.setState({type: body.type}, () => {this.setFileUrl(submission_file_id)})
              } else {
                const content = JSON.parse(body.content).replace(/\r?\n/gm, '\n');
                this.setState({content: content, type: body.type, loading: false});
              }
            })
      } else {
        if (this.props.selectedFileType === 'image' || this.props.selectedFileType === 'pdf') {
          this.setState({type: this.props.selectedFileType}, () => {this.setFileUrl()});
        } else {
          $.ajax({
            url: this.props.selectedFileURL,
            data: {preview: true, force_text: force_text},
            method: 'GET'
          }).then(res => {
            this.setState({content: res.replace(/\r?\n/gm, '\n'), type: this.props.selectedFileType, loading: false});
          });
        }
      }
    });
  };

  render() {
    let commonProps;
    if (!this.props.selectedFileURL) {
      commonProps = {
        submission_file_id: this.props.selectedFile,
        annotations: this.props.annotations,
        released_to_students: this.props.released_to_students,
        resultView: !!this.props.result_id
      };
    } else {
      commonProps = {
        submission_file_id: null,
        annotations: [],
        released_to_students: null,
        resultView: !!this.props.result_id
      };
    }
    if (this.state.loading) {
      return I18n.t('working');
    } else if (this.state.type === 'image') {
      return <ImageViewer
        url={this.state.url}
        {...commonProps}
      />;
    } else if (this.state.type === 'pdf') {
      return <PDFViewer
        url={this.state.url}
        annotationFocus={this.props.annotationFocus}
        {...commonProps}
      />;
    } else if (this.state.type === 'jupyter-notebook') {
      return <JupyterNotebookViewer
        annotationFocus={this.props.annotationFocus}
        content={this.state.content}
        {...commonProps}
      />;
    } else if (this.state.type === 'binary') {
      return <BinaryViewer
        content={this.state.content}
        getAnyway={() => this.set_submission_file(this.props.selectedFile, true)}
        {...commonProps}
      />
    } else if (this.state.type !== '') {
      return <TextViewer
        type={this.state.type}
        content={this.state.content}
        focusLine={this.props.focusLine}
        {...commonProps}
      />;
    } else {
      return '';
    }
  }
}
