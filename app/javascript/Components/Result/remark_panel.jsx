import React from "react";
import {TextForm} from "./autosave_text_form";
import {ResultContext} from "./result_context";

export class RemarkPanel extends React.Component {
  static contextType = ResultContext;

  componentDidMount() {
    if (this.props.released_to_students) {
      const comment = this.props.overallComment;
      let target_id = "overall_remark_comment";
      document.getElementById(target_id).innerHTML = safe_marked(comment);
      MathJax.typeset([`#${target_id}`]);
    }

    if (this.props.remarkSubmitted) {
      const target_id = "remark_request_text";
      document.getElementById(target_id).innerHTML = safe_marked(this.props.remarkRequestText);
      MathJax.typeset(["#submitted_remark_request_text"]);
    }
  }

  submitRemarkRequest = (value, name) => {
    let data = {submission: {remark_request: value}};
    data[name] = "true";
    return $.ajax({
      url: Routes.update_remark_request_course_assignment_submission_path(
        this.context.course_id,
        this.context.assignment_id,
        this.context.submission_id
      ),
      method: "PATCH",
      data: data,
    });
  };

  render() {
    let remarkCommentElement;
    if (this.props.released_to_students) {
      remarkCommentElement = <div id="overall_remark_comment" className="preview" />;
    } else {
      remarkCommentElement = (
        <TextForm
          initialValue={this.props.overallComment}
          persistChanges={value => this.props.updateOverallComment(value, true)}
        />
      );
    }

    let remarkDueDate;
    if (this.props.remarkDueDate) {
      remarkDueDate =
        I18n.t("activerecord.attributes.assignment.remark_due_date") +
        ": " +
        I18n.l("time.formats.default", this.props.remarkDueDate);
    } else {
      remarkDueDate = I18n.t("results.remark.no_remark_due_date");
    }

    const extraInstructions = (
      <p>
        {I18n.t("results.remark.about_remark_save")}&nbsp;
        {I18n.t("results.remark.about_remark_submission")}&nbsp;
        {I18n.t("results.remark.cancel_remark_to_change")}
      </p>
    );

    let remarkRequestElement;
    if (this.props.studentView && !this.props.remarkSubmitted) {
      if (this.props.pastRemarkDueDate) {
        remarkRequestElement = I18n.t("results.remark.past_remark_due_date");
      } else {
        remarkRequestElement = (
          <RemarkRequestForm
            onSubmit={this.submitRemarkRequest}
            initialValue={this.props.remarkRequestText}
          />
        );
      }
    } else if (this.props.remarkSubmitted) {
      remarkRequestElement = (
        <div>
          <p>
            {I18n.t("results.remark.submitted_on", {
              time: I18n.l("time.formats.default", this.props.remarkRequestTimestamp),
            })}
          </p>
          <div id="remark_request_text" />
        </div>
      );
    } else {
      remarkRequestElement = "";
    }

    return (
      <div id="remark_request">
        <h2>{I18n.t("activerecord.attributes.assignment.remark_message")}</h2>
        <p>{this.props.assignmentRemarkMessage}</p>
        <p>{remarkDueDate}</p>
        {this.props.studentView && extraInstructions}
        <h2>{I18n.t("activerecord.attributes.submission.submitted_remark")}</h2>
        {remarkRequestElement}
        {(!this.props.studentView || this.props.remarkSubmitted) && (
          <h2>{I18n.t("activerecord.attributes.result.overall_comment")}</h2>
        )}
        <div>{remarkCommentElement}</div>
      </div>
    );
  }
}

class RemarkRequestForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: this.props.initialValue,
      unsavedChanges: false,
    };
    this.button = React.createRef();
  }

  componentDidMount() {
    this.renderPreview();
  }

  renderPreview = () => {
    let target_id = "remark-request-preview";
    document.getElementById(target_id).innerHTML = safe_marked(this.state.value);
    MathJax.typeset([`#${target_id}`]);
  };

  updateValue = event => {
    const value = event.target.value;
    this.setState({value: value, unsavedChanges: true}, this.renderPreview);
  };

  onSubmit = event => {
    event.preventDefault();
    this.props.onSubmit(this.state.value, event.target.name).then(() => {
      Rails.enableElement(this.button.current);
      this.setState({unsavedChanges: false});
    });
  };

  render() {
    return (
      <div className={this.props.className || ""}>
        <form>
          <textarea value={this.state.value} onChange={this.updateValue} rows={10} />
          <p>
            <input
              type="submit"
              value={I18n.t("save")}
              name="save"
              data-disable-with={I18n.t("working")}
              ref={this.button}
              disabled={!this.state.unsavedChanges}
              onClick={e => this.onSubmit(e)}
            />
            <input
              type="submit"
              value={I18n.t("results.remark.submit")}
              name="submit"
              data-disable-with={I18n.t("working")}
              data-confirm={I18n.t("results.remark.submit_confirm")}
              onClick={e => this.onSubmit(e)}
            />
          </p>
          <h3>{I18n.t("preview")}</h3>
          <div id="remark-request-preview" className="preview"></div>
        </form>
      </div>
    );
  }
}
