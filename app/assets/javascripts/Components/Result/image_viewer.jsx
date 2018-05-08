import React from 'react';
import {render} from 'react-dom';


export class ImageViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidMount() {
    if (this.props.url) {
      source_code_ready_for_image();
      annotationTable.display_annotations(this.props.submission_file_id);
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.url) {
      source_code_ready_for_image();
      annotationTable.display_annotations(this.props.submission_file_id);
    }
  }

  render() {
    return (
      <div id='image_container' className='image_container'>
        <img id='image_preview'
          src={this.props.url}
          alt={I18n.t('common.cant_display_image')} />
      </div>
    );
  }
}
