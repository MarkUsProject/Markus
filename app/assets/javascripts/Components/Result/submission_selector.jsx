import React from "react";
import {render} from "react-dom";
import PropTypes from "prop-types";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

export class SubmissionSelector extends React.Component {
  renderToggleMarkingStateButton = () => {
    let buttonText, className, disabled, icon;
    if (this.props.marking_state === "complete") {
      buttonText = I18n.t("results.set_to_incomplete");
      className = "set-incomplete";
      disabled = this.props.released_to_students;
      icon = <FontAwesomeIcon icon="fa-solid fa-pen" />;
    } else {
      buttonText = I18n.t("results.set_to_complete");
      className = "set-complete";
      disabled = this.props.marks.some(mark => mark.mark === null || mark.mark === undefined);
      icon = <FontAwesomeIcon icon="fa-solid fa-circle-check" />;
    }
    return (
      <button
        onClick={this.props.toggleMarkingState}
        className={className}
        disabled={disabled}
        style={{alignSelf: "flex-end", width: "140px"}}
      >
        {icon}
        {buttonText}
      </button>
    );
  };

  renderReleaseMarksButton() {
    if (!this.props.can_release) return "";

    let buttonText, disabled;
    if (this.props.released_to_students) {
      buttonText = I18n.t("submissions.unrelease_marks");
      disabled = false;
    } else {
      buttonText = I18n.t("submissions.release_marks");
      disabled = this.props.marking_state !== "complete";
    }
    return (
      <button
        className="release"
        onClick={this.props.setReleasedToStudents}
        disabled={disabled}
        style={{alignSelf: "flex-end"}}
      >
        <FontAwesomeIcon icon="fa-solid fa-envelope-circle-check" />
        {buttonText}
      </button>
    );
  }

  renderFullscreenButton() {
    if (this.props.fullscreen) {
      return (
        <button
          className="fullscreen-exit"
          onClick={this.props.toggleFullscreen}
          style={{alignSelf: "flex-end"}}
          title="Alt + Enter"
        >
          <FontAwesomeIcon icon="fa-solid fa-compress" />
          {I18n.t("results.fullscreen_exit")}
        </button>
      );
    } else {
      return (
        <button
          className="fullscreen-enter"
          onClick={this.props.toggleFullscreen}
          style={{alignSelf: "flex-end"}}
          title="Alt + Enter"
        >
          <FontAwesomeIcon icon="fa-solid fa-expand" />
          {I18n.t("results.fullscreen_enter")}
        </button>
      );
    }
  }

  renderPrintButton() {
    return (
      <a
        className={"button"}
        href={Routes.print_course_result_path(this.props.course_id, this.props.result_id)}
        style={{alignSelf: "flex-end"}}
      >
        {I18n.t("results.print")}
      </a>
    );
  }

  render() {
    if (this.props.role === "Student" && !this.props.is_reviewer) {
      return "";
    }

    const url = Routes.next_grouping_course_result_path(this.props.course_id, this.props.result_id);

    const progressBarWidth =
      this.props.num_collected > 0 ? this.props.num_marked / this.props.num_collected : 1;
    let progressBarColour;
    if (progressBarWidth > 0.75) {
      progressBarColour = "green";
    } else if (progressBarWidth > 0.35) {
      progressBarColour = "#FBC02D";
    } else {
      progressBarColour = "#FE2A2A";
    }

    let meterLow = 0;
    let meterHigh = 1;
    if (this.props.num_collected !== null && this.props.num_collected !== undefined) {
      meterLow = this.props.num_collected * 0.35;
      meterHigh = this.props.num_collected * 0.75;
    }

    return (
      <div className="submission-selector-container">
        <div className="submission-selector">
          <button
            className="button previous"
            onClick={this.props.previousSubmission}
            title={`${I18n.t("results.previous_submission")} (Shift + ⇦)`}
          >
            <FontAwesomeIcon icon="fa-solid fa-arrow-left" className="no-padding" />
          </button>
          <h3 className="group-name">{this.props.group_name}</h3>
          <button
            className="button next"
            onClick={this.props.nextSubmission}
            title={`${I18n.t("results.next_submission")} (Shift + ⇨)`}
          >
            <FontAwesomeIcon icon="fa-solid fa-arrow-right" className="no-padding" />
          </button>
          <div className="progress">
            <meter
              value={this.props.num_marked}
              min={0}
              max={this.props.num_collected}
              low={meterLow}
              high={meterHigh}
              optimum={this.props.num_collected}
            >
              {this.props.num_marked}/{this.props.num_collected}
            </meter>
            {this.props.num_marked}/{this.props.num_collected}&nbsp;
            {I18n.t("submissions.state.complete")}
          </div>

          <div style={{flexGrow: 1}} />
          <h2 className="total">
            {+(Math.round(this.props.total * 100) / 100)} / {+this.props.assignment_max_mark}
          </h2>
          {this.renderPrintButton()}
          {this.renderToggleMarkingStateButton()}
          {this.renderReleaseMarksButton()}
          {this.renderFullscreenButton()}
        </div>
      </div>
    );
  }
}

SubmissionSelector.propTypes = {
  assignment_max_mark: PropTypes.number,
  can_release: PropTypes.bool,
  course_id: PropTypes.number.isRequired,
  fullscreen: PropTypes.bool,
  group_name: PropTypes.string,
  is_reviewer: PropTypes.bool,
  marking_state: PropTypes.string,
  marks: PropTypes.arrayOf(PropTypes.object),
  nextSubmission: PropTypes.func,
  num_collected: PropTypes.number,
  num_marked: PropTypes.number,
  previousSubmission: PropTypes.func,
  released_to_students: PropTypes.bool,
  result_id: PropTypes.number.isRequired,
  role: PropTypes.string,
  setReleasedToStudents: PropTypes.func,
  toggleFullscreen: PropTypes.func,
  toggleMarkingState: PropTypes.func,
  total: PropTypes.number,
};
