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

    let imgH = document.getElementById('image_preview').height;
    let imgW = document.getElementById('image_preview').width;

    if (this.state.rotation === 90 || this.state.rotation === 270) {
      let originalImgW = imgH;
      let originalImgH = imgW;
    } else {
      let originalImgW = imgW;
      let originalImgH = imgH;
    }

    let topLeft = [annotation.x_range.start - originalImgW/2, annotation.y_range.start - originalImgH/2];
    let topRight = [annotation.x_range.end - originalImgW/2, annotation.y_range.start - originalImgH/2];
    let bottomLeft = [annotation.x_range.start - originalImgW/2, annotation.y_range.end - originalImgH/2];
    let rotatedTR = this.rotatedCoordinate(topRight);
    let rotatedTL = this.rotatedCoordinate(topLeft);
    let rotatedBL = this.rotatedCoordinate(bottomLeft);

    annotation_manager.add_to_grid({
      x_range: {
        start: imgW/2 + rotatedTL[0],
        end: imgW/2 + rotatedTR[0]
      },
      y_range: {
        start: imgH/2 + rotatedTL[1],
        end: imgH/2 + rotatedBL[1]
      },
      annot_id: annotation.id,
      // TODO: rename the following
      id: annotation.annotation_text_id
    });
  };

  rotatedCoordinate = (coordinate, axis) => {
    // Rotate the point
  }

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
    return ([
      <p>
        Current rotation = {this.state.rotation}°
        <button onClick={this.addRotation} className={'inline-button'}>Rotate 90° degrees</button>
      </p>,
      <div id='image_container'>
        <div key='sel_box' id='sel_box' className='annotation-holder-active' style={{display: 'none'}}/>
        <img id='image_preview'
          src={this.props.url}
          onLoad={this.display_annotations}
          alt={I18n.t('results.cant_display_image')} />
      </div>
    ]);
  }
}
