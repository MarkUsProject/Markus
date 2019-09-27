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
    const comment = this.state.overallComment;
    let target_id;
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      target_id = 'overall_comment_text';
    } else {
      target_id = 'overall_comment_preview';
    }
    document.getElementById(target_id).innerHTML = marked(comment, {sanitize: true});
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, target_id]);
  }

  componentDidUpdate(prevProps) {
    if (prevProps.overallComment !== this.props.overallComment) {
      this.setState({overallComment: this.props.overallComment});
    }
  }

  updateOverallComment = (event) => {
    const comment = event.target.value;
    this.setState({overallComment: comment, unsavedChanges: true});
    document.getElementById('overall_comment_preview').innerHTML = marked(comment, {sanitize: true});
    MathJax.Hub.Queue(['Typeset', MathJax.Hub, 'overall_comment_preview']);
  };

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
      overallCommentElement = <div id='overall_comment_text' />;
    } else {
      overallCommentElement = (
        <div className="overall-comment">
          <form onSubmit={this.submitOverallComment}>
            <textarea
              value={this.state.overallComment}
              onChange={this.updateOverallComment}
              rows={5}
            />
            <input type="submit" value={I18n.t('save')}
                   data-disable-with={I18n.t('working')}
                   ref={this.submitOverallCommentButton}
                   disabled={!this.state.unsavedChanges}
            />
          </form>
          <h3>{I18n.t('preview')}</h3>
          <div id="overall_comment_preview" />
        </div>
      );
    }

    return (
      <div>
        <h3>{I18n.t('activerecord.attributes.result.overall_comment')}</h3>
        {overallCommentElement}

        <h3>{I18n.t('activerecord.models.annotation.other')}</h3>
        <p>{I18n.t('results.annotation.across_all_submission_files')}</p>
        <AnnotationTable
          detailed={this.props.detailed}
          released_to_students={this.props.released_to_students}
          annotations={this.props.annotations}
          editAnnotation={this.props.editAnnotation}
          removeAnnotation={this.props.removeAnnotation}
          selectFile={this.props.selectFile}
        />
      </div>
    )
  }
}
