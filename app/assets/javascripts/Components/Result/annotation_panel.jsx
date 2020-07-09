import React from 'react';

import { AnnotationTable } from './annotation_table';


export class AnnotationPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      overallComment: props.overallComment,
      unsavedChanges: false
    };
    this.submitOverallCommentButton = React.createRef();
  }

  componentDidMount() {
    this.renderOverallCommentText();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.overallComment !== this.props.overallComment) {
      this.setState({overallComment: this.props.overallComment});
    } else if (prevState.overallComment !== this.state.overallComment) {
      this.renderOverallCommentText();
    }
  }

  updateOverallComment = (event) => {
    const comment = event.target.value;
    this.setState({overallComment: comment, unsavedChanges: true});
  };

  renderOverallCommentText() {
    let target_id;
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      target_id = 'overall_comment_text';
    } else {
      target_id = 'overall_comment_preview';
    }
    document.getElementById(target_id).innerHTML = marked(this.state.overallComment, {sanitize: true});
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, target_id]);
  }

  submitOverallComment = (event) => {
    $.post({
      url: Routes.update_overall_comment_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id,
      ),
      data: {result: {overall_comment: this.state.overallComment}},
    }).then(() => {
      Rails.enableElement(this.submitOverallCommentButton.current);
      this.setState({unsavedChanges: false});
    });
    event.preventDefault();
  };

  render() {
    let overallCommentElement;
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      overallCommentElement = <div id='overall_comment_text' key='overall_comment_text' />;
    } else {
      overallCommentElement = (
        <div key='overall_comment_text'>
          <form onSubmit={this.submitOverallComment}>
            <textarea
              value={this.state.overallComment}
              onChange={this.updateOverallComment}
              rows={5}
            />
            <p>
              <input type="submit" value={I18n.t('save')}
                     data-disable-with={I18n.t('working')}
                     ref={this.submitOverallCommentButton}
                     disabled={!this.state.unsavedChanges}
              />
            </p>
          </form>
          <h3>{I18n.t('preview')}</h3>
          <div id="overall_comment_preview" className="preview"/>
        </div>
      );
    }

    return [
      <h3 key="h3-overall-comment">{I18n.t('activerecord.attributes.result.overall_comment')}</h3>,
      overallCommentElement,
      <h3 key="h3-annotations">{I18n.t('activerecord.models.annotation.other')}</h3>,
      <p key="annotations-desription">{I18n.t('results.annotation.across_all_submission_files')}</p>,
      <AnnotationTable
        key="annotations-table"
        detailed={this.props.detailed}
        released_to_students={this.props.released_to_students}
        annotations={this.props.annotations}
        editAnnotation={this.props.editAnnotation}
        removeAnnotation={this.props.removeAnnotation}
        selectFile={this.props.selectFile}
      />
    ];
  }
}
