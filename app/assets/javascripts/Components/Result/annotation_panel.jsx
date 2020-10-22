import React from "react";
import { AnnotationTable } from "./annotation_table";
import { TextForm } from "./autosave_text_form";

export class AnnotationPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      overallComment: props.overallComment,
    };
  }

  componentDidMount() {
    this.renderReleasedComments();
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.overallComment !== this.props.overallComment) {
      this.setState({overallComment: this.props.overallComment});
    } else if (prevState.overallComment !== this.state.overallComment) {
      this.renderReleasedComments();
    }
  }

  renderReleasedComments() {
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      let target_id = "overall_comment_text";
      document.getElementById(target_id).innerHTML = marked(
        this.state.overallComment,
        { sanitize: true }
      );
      MathJax.Hub.Queue(["Typeset", MathJax.Hub, target_id]);
    }
  }

  persistChanges = (value) => {
    return $.post({
      url: Routes.update_overall_comment_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      data: { result: { overall_comment: value } },
    });
  };

  render() {
    let overallCommentElement;
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      overallCommentElement = <div id='overall_comment_text' key='overall_comment_text' />;
    } else {
      overallCommentElement = (
        <TextForm
          initialValue={this.props.overallComment}
          persistChanges={this.persistChanges}
          previewId={"overall_comment_preview"}
        />
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
