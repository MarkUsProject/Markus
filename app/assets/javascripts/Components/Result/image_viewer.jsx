import React from 'react';
import {render} from 'react-dom';


export class ImageViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      rotation: 0
    };
  }

  componentDidUpdate(prevProps, prevState) {
    this.display_annotations();
  }

  display_annotations = () => {
    if (this.props.resultView && this.props.url) {
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
    let content = '';
    if (!annotation.deduction) {
      content += annotation.content;
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

  addRotation = () => {
    this.setState({rotation: this.state.rotation + 90 > 270 ? 0 : this.state.rotation + 90}, this.rotateImage)
  }

  rotateImage = () => {
    let picture = document.getElementById('image_preview');
    let dimensions = picture.getBoundingClientRect();
    if (this.state.rotation === 0) {
      picture.removeAttribute('class');
    } else {
      picture.setAttribute('class', 'rotate' + this.state.rotation.toString());
    }
  }

  render() {
    return (
      <div id='image_container'>
        <p>
          Current rotation = {this.state.rotation}°
          <button onClick={this.addRotation} className={'inline-button'}>Rotate 90° degrees</button>
        </p>
        <div key='sel_box' id='sel_box' className='annotation-holder-active' style={{display: 'none'}}/>
        <img id='image_preview'
          src={this.props.url}
          onLoad={this.display_annotations}
          alt={I18n.t('results.cant_display_image')} />
      </div>
    );
  }
}
