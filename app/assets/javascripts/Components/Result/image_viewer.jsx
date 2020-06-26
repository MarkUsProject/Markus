import React from 'react';
import {render} from 'react-dom';


export class ImageViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidUpdate(prevProps, prevState) {
    this.display_annotations();
  }

  display_annotations = () => {
    if (this.props.url) {
      this.ready_annotations();
      this.props.annotations.forEach(this.display_annotation);
    }
  };

  ready_annotations = () => {
    window.annotation_type = ANNOTATION_TYPES.IMAGE;

    $('.annotation_holder').remove();
    annotation_manager = new ImageAnnotationGrid(
      new ImageEventHandler(),
      new AnnotationTextManager(),
      new AnnotationTextDisplayer(),
      !this.props.released_to_students
    );
  };

  display_annotation = (annotation) => {
    add_annotation_text(annotation.annotation_text_id, annotation.content);
    annotation_manager.add_to_grid({
      x_range: annotation.x_range,
      y_range: annotation.y_range,
      annot_id: annotation.id,
      // TODO: rename the following
      id: annotation.annotation_text_id
    });
  };

  render() {
    return (
      <div id='image_container' className='image_container'>
        <div key='sel_box' id='sel_box' className='annotation-holder-active' style={{display: 'none'}}/>
        <img id='image_preview'
          src={this.props.url}
          onLoad={this.display_annotations}
          alt={I18n.t('results.cant_display_image')} />
      </div>
    );
  }
}
