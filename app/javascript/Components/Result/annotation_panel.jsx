import React from "react";
import {AnnotationTable} from "./annotation_table";
import {TextForm} from "./autosave_text_form";

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
      document.getElementById(target_id).innerHTML = safe_marked(this.state.overallComment);
      MathJax.typeset([`#${target_id}`]);
    }
  }

  render() {
    let overallCommentElement;
    if (this.props.released_to_students || this.props.remarkSubmitted) {
      overallCommentElement = (
        <div id="overall_comment_text" className="preview" key="overall_comment_text" />
      );
    } else {
      overallCommentElement = (
        <TextForm
          initialValue={this.props.overallComment}
          persistChanges={this.props.updateOverallComment}
        />
      );
    }
    return (
      <React.Fragment>
        <h2 key="h3-overall-comment">{I18n.t("activerecord.attributes.result.overall_comment")}</h2>
        <div>{overallCommentElement}</div>
        <h2 key="h3-annotations">{I18n.t("activerecord.models.annotation.other")}</h2>
        <p key="annotations-desription">
          {I18n.t("results.annotation.across_all_submission_files")}
        </p>
        <AnnotationTable
          key="annotations-table"
          detailed={this.props.detailed}
          released_to_students={this.props.released_to_students}
          remark_submitted={this.props.remarkSubmitted}
          annotations={this.props.annotations}
          editAnnotation={this.props.editAnnotation}
          removeAnnotation={this.props.removeAnnotation}
          selectFile={this.props.selectFile}
        />
      </React.Fragment>
    );
  }
}
