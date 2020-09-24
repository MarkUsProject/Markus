import React from 'react';
import {render} from 'react-dom';


export class ImageViewer extends React.Component {
  constructor() {
    super();
    this.state = {
      rotation: 0,
      zoom: 1,
      heightChange: 0,
      widthChange: 0
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


    let originalImgH = document.getElementById('image_preview').height;
    let originalImgW = document.getElementById('image_preview').width;
    let imgW;
    let imgH;

    if (this.state.rotation === 90 || this.state.rotation === 270) {
      imgW = originalImgH;
      imgH = originalImgW;
    } else {
      imgW = originalImgW;
      imgH = originalImgH;
    }

    // this is wrong
    // let xzoom = Math.floor(this.state.zoom * (annotation.x_range.end - annotation.x_range.start) / 2);
    // let yzoom = Math.floor(this.state.zoom * (annotation.y_range.end - annotation.y_range.start) / 2);

    let topLeft = [
      annotation.x_range.start - (originalImgW / 2) - xzoom,
      annotation.y_range.start - (originalImgH / 2) - yzoom
    ];
    let topRight = [
      annotation.x_range.end - (originalImgW / 2) + xzoom,
      annotation.y_range.start - (originalImgH / 2) - yzoom
    ];
    let bottomLeft = [
      annotation.x_range.start - (originalImgW / 2) - xzoom,
      annotation.y_range.end - (originalImgH / 2) + yzoom
    ];
    let bottomRight = [
      annotation.x_range.end - (originalImgW / 2) + xzoom,
      annotation.y_range.end - (originalImgH / 2) + yzoom
    ];

    let rotatedTR = this.rotatedCoordinate(topRight, this.state.rotation);
    let rotatedTL = this.rotatedCoordinate(topLeft, this.state.rotation);
    let rotatedBL = this.rotatedCoordinate(bottomLeft, this.state.rotation);
    let rotatedBR = this.rotatedCoordinate(bottomRight, this.state.rotation);

    let corners;

    // index of coordinates in corners array matching position in plane
    //    1 - 2
    //    |
    //    0
    switch (this.state.rotation) {
      case 90:
        corners = [rotatedBR, rotatedBL, rotatedTL];
        break;
      case 180:
        corners = [rotatedTR, rotatedBR, rotatedBL];
        break;
      case 270:
        corners = [rotatedTL, rotatedTR, rotatedBR];
        break;
      default:
        corners = [rotatedBL, rotatedTL, rotatedTR];
    }


    annotation_manager.add_to_grid({
      x_range: {
        start: imgW/2 + corners[1][0],
        end: imgW/2 + corners[2][0]
      },
      y_range: {
        start: imgH/2 + corners[1][1],
        end: imgH/2 + corners[0][1]
      },
      annot_id: annotation.id,
      // TODO: rename the following
      id: annotation.annotation_text_id
    });
  };



  rotatedCoordinate = (coordinate, rotation) => {
    if (rotation > 0) {
      return this.rotatedCoordinate([-coordinate[1], coordinate[0]], rotation - 90);

    }
    return coordinate;
  }

  addRotation = () => {
    this.setState({rotation: this.state.rotation + 90 > 270 ? 0 : this.state.rotation + 90}, this.rotateImage);
  }
  zoomIn = () => {
    let picture = document.getElementById('image_preview');
    if (this.state.heightChange === 0 && this.state.zoom === 1) {
      let widthIncrease = Math.floor(picture.width * .10);
      let heightIncrease = Math.floor(picture.height * .10);
      this.setState({
        widthChange: widthIncrease,
        heightChange: heightIncrease,
        zoom: 1.1
      });
      picture.width = picture.width + widthIncrease;
      picture.height = picture.height + heightIncrease;
    } else {
      picture.width = picture.width + this.state.widthChange;
      picture.height = picture.height + this.state.heightChange;
      this.setState({zoom: this.state.zoom + .1});
    }
  }
  zoomOut = () => {
    let picture = document.getElementById('image_preview');
    if (this.state.heightChange === 0 && this.state.zoom === 1) {
      let widthIncrease = Math.floor(picture.width * .10);
      let heightIncrease = Math.floor(picture.height * .10);
      this.setState({
        widthChange: widthIncrease,
        heightChange: heightIncrease,
        zoom: 1.1
      });
      picture.width = picture.width - widthIncrease;
      picture.height = picture.height - heightIncrease;
    } else if (this.state.zoom > 0) {
      picture.width = picture.width - this.state.widthChange;
      picture.height = picture.height - this.state.heightChange;
      this.setState({zoom: this.state.zoom - .1});
    }
  }

  rotateImage = () => {
    let picture = document.getElementById('image_preview');

    if (this.state.rotation > 0) {
      picture.addClass('rotate' + this.state.rotation.toString());
      picture.removeClass('rotate' + (this.state.rotation - 90).toString());
    } else {
      picture.removeClass('rotate270');
    }

  }

  render() {
    return ([




      <p key={'image_toolbar'}>
        {I18n.t('results.current_rotation', {rotation: this.state.rotation})}
        <button onClick={this.addRotation} className={'inline-button'}>{I18n.t('results.rotate_image')}</button>
        Current zoom level = {Math.floor(this.state.zoom * 100)}%
        <button onClick={this.zoomIn} className={'inline-button'}>Zoom +</button>
        <button onClick={this.zoomOut} className={'inline-button'}>Zoom -</button>
      </p>,
      <div id='image_container' key={'image_container'}>


        <div key='sel_box' id='sel_box' className='annotation-holder-active' style={{display: 'none'}}/>
        <img id='image_preview'
          src={this.props.url}
          onLoad={this.display_annotations}
          alt={I18n.t('results.cant_display_image')} />
      </div>
    ]);
  }
}
