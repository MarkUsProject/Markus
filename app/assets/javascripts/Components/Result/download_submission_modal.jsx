import React from 'react';
import { FileSelector } from './submission_file_panel';


export class DownloadSubmissionModal extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      selectedFile: this.props.initialFile,
      includeAnnotations: false
    };
  }

  componentDidUpdate(prevProps) {
    if (prevProps.initialFile !== this.props.initialFile) {
      this.setState({selectedFile: this.props.initialFile});
    }
  }

  selectFile = (file, id) => {
    this.setState({selectedFile: [file, id]});
  };

  render() {
    let downloadSingleURL = new URL(this.props.downloadURL);
    downloadSingleURL.searchParams.append('select_file_id', this.state.selectedFile && this.state.selectedFile[1]);
    downloadSingleURL.searchParams.append('include_annotations', this.state.includeAnnotations);

    let downloadAllURL = new URL(this.props.downloadURL);
    downloadAllURL.searchParams.append('download_zip_button', true);
    downloadAllURL.searchParams.append('include_annotations', this.state.includeAnnotations);

    return (
      <div>
        <div>
          <input
            name='include_annotations'
            id='include_annotations'
            type='checkbox'
            value={this.state.includeAnnotations}
            onChange={(e) => this.setState({includeAnnotations: e.target.checked})}
          />
          <label htmlFor='include_annotations' className='inline_label'>
            {I18n.t('results.annotation.include_in_download')}
          </label>
          <p>
            {I18n.t('results.annotation.include_in_download_warning')}
          </p>
        </div>
        <div id='download_file_selector'>
          <FileSelector
            fileData={this.props.fileData}
            onSelectFile={this.selectFile}
            selectedFile={this.state.selectedFile}
          />
          <div style={{clear: 'left'}} />
        </div>
        <div>
          {this.state.selectedFile === null ?
            <a
              className='button disabled'
              href={'#'}
              download
            >
              {I18n.t('download')}
            </a>
            :
            <a
              className='button'
              href={downloadSingleURL}
              download
            >
              {I18n.t('download')}
            </a>
          }
          <a
            className='button'
            href={downloadAllURL}
            download
          >
            {I18n.t('download_the', {item: I18n.t('all')})}
          </a>
        </div>
      </div>
    );
  }
}
