import React from 'react';
import heic2any from "heic2any";

import {ImageViewer} from './image_viewer'
import {TextViewer} from './text_viewer'
import {PDFViewer} from './pdf_viewer';


export class FileViewer extends React.Component {
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
    if (this.props.selectedFile !== null) {
      this.set_submission_file(this.props.selectedFile);
    } else {
      this.setState({loading: false})
    }
  }

  // Manually manage a change of selectedFile, as this requires fetching new file data.
  shouldComponentUpdate(nextProps) {
    if (this.props.selectedFile !== nextProps.selectedFile) {
      this.set_submission_file(nextProps.selectedFile);
      return false;
    } else {
      return true;
    }
  }

  setFileUrl = (submission_file_id) => {
    let url = Routes.download_assignment_submission_result_path(
      '',
      this.props.assignment_id,
      this.props.submission_id,
      this.props.result_id,
      {
        select_file_id: submission_file_id,
        show_in_browser: true,
        from_codeviewer: true,
      }
    );
    if (['image/heic', 'image/heif'].includes(this.props.mime_type)) {
      fetch(url)
        .then((res) => res.blob())
        .then((blob) => heic2any({blob, toType:"image/jpeg"}))
        .then((conversionResult) => {this.setState({url: URL.createObjectURL(conversionResult), loading: false})})
    } else {
      this.setState({url: url, loading: false})
    }
  };

  /*
   * Update the contents being displayed with the given submission file id.
   */
  set_submission_file = (submission_file_id) => {
    // TODO: is this the right spot to remove these? Should it be done earlier?
    $('.annotation_text_display').each(function() {
      this.remove();
    });

    this.setState({loading: true, url: null}, () => {
      fetch(Routes.get_file_assignment_submission_path(
              '',
              this.props.assignment_id,
              this.props.submission_id,
              {submission_file_id: submission_file_id}),
            {credentials: 'include'})
        .then(res => res.json())
        .then(body => {
          if (body.type === 'image' || body.type === 'pdf') {
            this.setState({type: body.type}, () => {
              this.setFileUrl(submission_file_id)
            })
          } else {
            const content = JSON.parse(body.content).replace(/\r?\n/gm, '\n');
            this.setState({content: content, type: body.type, loading: false});
          }
        })
    });
  };

  render() {
    const commonProps = {
      submission_file_id: this.props.selectedFile,
      annotations: this.props.annotations,
      released_to_students: this.props.released_to_students
    };
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
        {...commonProps}
      />;
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
