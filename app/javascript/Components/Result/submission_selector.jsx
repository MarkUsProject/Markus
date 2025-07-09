import React from "react";
import PropTypes from "prop-types";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {FilterModal} from "../Modals/filter_modal";
import {
  bind_keybindings,
  unbind_all_keybindings,
} from "../../../assets/javascripts/Results/keybinding";
import {ResultContext} from "./result_context";

export class SubmissionSelector extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showFilterModal: false,
    };
  }
  componentDidMount() {
    bind_keybindings();
  }

  componentWillUnmount() {
    unbind_all_keybindings();
  }

  static contextType = ResultContext;

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
        title={buttonText}
      >
        {icon}
        <span className="button-text">{buttonText}</span>
      </button>
    );
  };

  renderReleaseMarksButton() {
    if (!this.props.can_release) return "";

    let buttonText, disabled, icon;
    if (this.props.released_to_students) {
      buttonText = I18n.t("submissions.unrelease_marks");
      disabled = false;
      icon = (
        <span className="fa-layers fa-fw">
          <FontAwesomeIcon
            icon="fa-solid fa-envelope-circle-check"
            color={document.documentElement.style.getPropertyValue("--disabled_text")}
          />
          <FontAwesomeIcon icon="fa-solid fa-slash" />
        </span>
      );
    } else {
      buttonText = I18n.t("submissions.release_marks");
      disabled = this.props.marking_state !== "complete";
      icon = <FontAwesomeIcon icon="fa-solid fa-envelope-circle-check" />;
    }
    return (
      <button
        className="release"
        onClick={this.props.setReleasedToStudents}
        disabled={disabled}
        style={{alignSelf: "flex-end"}}
        title={buttonText}
      >
        {icon}
        <span className="button-text">{buttonText}</span>
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
          title={`${I18n.t("results.fullscreen_exit")} (Alt + Enter)`}
        >
          <FontAwesomeIcon icon="fa-solid fa-compress" />
          <span className="button-text">{I18n.t("results.fullscreen_exit")}</span>
        </button>
      );
    } else {
      return (
        <button
          className="fullscreen-enter"
          onClick={this.props.toggleFullscreen}
          style={{alignSelf: "flex-end"}}
          title={`${I18n.t("results.fullscreen_enter")} (Alt + Enter)`}
        >
          <FontAwesomeIcon icon="fa-solid fa-expand" />
          <span className="button-text">{I18n.t("results.fullscreen_enter")}</span>
        </button>
      );
    }
  }

  renderPrintButton() {
    if (!this.context.is_reviewer) {
      return (
        <a
          className={"button"}
          href={Routes.print_course_result_path(this.context.course_id, this.context.result_id)}
          style={{alignSelf: "flex-end"}}
          title={I18n.t("results.print")}
        >
          <FontAwesomeIcon icon={"fa-solid fa-print"} />
          <span className="button-text">{I18n.t("results.print")}</span>
        </a>
      );
    }
  }

  onOpenFilterModal = () => {
    this.setState({showFilterModal: true});
  };

  renderFilterButton() {
    if (this.context.role !== "Student") {
      return (
        <button
          className="button filter"
          onClick={this.onOpenFilterModal}
          title={I18n.t("results.filter_submissions")}
        >
          <FontAwesomeIcon icon="fa-solid fa-filter" className="no-padding" />
        </button>
      );
    }
  }

  renderRandomIncompleteSubmissionButton() {
    if (this.context.role !== "Student") {
      return (
        <button
          className="button random-incomplete-submission"
          onClick={this.props.randomIncompleteSubmission}
          title={`${I18n.t("results.random_incomplete_submission")} (Ctrl + Shift + ⇨)`}
          disabled={this.props.num_collected === this.props.num_marked}
        >
          <FontAwesomeIcon icon="fa-solid fa-dice" className="no-padding" />
        </button>
      );
    }
  }

  renderFilterModal() {
    if (this.context.role !== "Student") {
      return (
        <div>
          <FilterModal
            isOpen={this.state.showFilterModal}
            onRequestClose={() => this.setState({showFilterModal: false})}
            filterData={this.props.filterData}
            updateFilterData={this.props.updateFilterData}
            clearAllFilters={this.props.clearAllFilters}
            sections={this.props.sections}
            tas={this.props.tas}
            available_tags={this.props.available_tags}
            current_tags={this.props.current_tags}
            loading={this.props.loading}
            criterionSummaryData={this.props.criterionSummaryData}
          />
        </div>
      );
    }
  }

  render() {
    if (this.context.role === "Student" && !this.context.is_reviewer) {
      return "";
    }

    let meterLow = 0;
    let meterHigh = 1;
    if (this.props.num_collected !== null && this.props.num_collected !== undefined) {
      meterLow = this.props.num_collected * 0.35;
      meterHigh = this.props.num_collected * 0.75;
    }

    return (
      <div className="submission-selector-container" data-testid="submission-selector-container">
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
          {this.renderRandomIncompleteSubmissionButton()}
          {this.renderFilterButton()}
          <div className="progress">
            <meter
              value={this.props.num_marked}
              min={0}
              max={this.props.num_collected}
              low={meterLow}
              high={meterHigh}
              optimum={this.props.num_collected}
              data-testid="progress-bar"
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
        {this.renderFilterModal()}
      </div>
    );
  }
}

SubmissionSelector.propTypes = {
  assignment_max_mark: PropTypes.number,
  can_release: PropTypes.bool,
  fullscreen: PropTypes.bool,
  group_name: PropTypes.string,
  marking_state: PropTypes.string,
  marks: PropTypes.arrayOf(PropTypes.object),
  nextSubmission: PropTypes.func,
  num_collected: PropTypes.number,
  num_marked: PropTypes.number,
  previousSubmission: PropTypes.func,
  released_to_students: PropTypes.bool,
  setReleasedToStudents: PropTypes.func,
  toggleFullscreen: PropTypes.func,
  toggleMarkingState: PropTypes.func,
  total: PropTypes.number,
};
