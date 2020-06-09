import React from 'react';
import {render} from 'react-dom';


export class ImageViewer extends React.Component {
  constructor() {
    super();
  }

  componentDidMount() {
    if (this.props.url) {
      this.ready_annotations();
      this.props.annotations.forEach(this.display_annotation);
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.props.url) {
      this.ready_annotations();
      this.props.annotations.forEach(this.display_annotation);
    }
  }

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

  componentWillUnmount() {
    let box = document.getElementById('sel_box');
    if (box) {
      box.style.display = 'none';
      box.style.width   = '0';
      box.style.height  = '0';
    }
  }

  display_annotation = (annotation) => {
    let content = '';
    if (annotation.deduction === undefined || annotation.deduction === null || annotation.deduction === 0.0){
      content += annotation.content
    } else {
      content += annotation.content + ' [' + annotation.criterion_name + ': -' + annotation.deduction + ']';
    }
    add_annotation_text(annotation.annotation_text_id, content);
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
        <img id='image_preview'
          src={this.props.url}
          alt={I18n.t('results.cant_display_image')} />
      </div>
    );
  }
}
