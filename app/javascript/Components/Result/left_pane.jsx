import React from "react";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {AnnotationPanel} from "./annotation_panel";
import {FeedbackFilePanel} from "./feedback_file_panel";
import {RemarkPanel} from "./remark_panel";
import {SubmissionFilePanel} from "./submission_file_panel";
import {TestRunTable} from "../test_run_table";
import {ResultContext} from "./result_context";

export class LeftPane extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tabIndex: 0,
    };
    this.submissionFilePanel = React.createRef();
  }

  static contextType = ResultContext;

  getSelectedTabIndex() {
    // Reset selected tab state if props are changed and a tab becomes disabled.
    // Affected tabs are "Test Results" (tabIndex 2), "Feedback Files" (tabIndex 3),
    // and "Remark Request" (tabIndex 4).
    if (
      (this.state.tabIndex === 2 && this.disableTestResultsPanel()) ||
      (this.state.tabIndex === 3 && this.disableFeedbackFilesPanel()) ||
      (this.state.tabIndex === 4 && this.disableRemarkPanel())
    ) {
      return 0;
    } else {
      return this.state.tabIndex;
    }
  }

  disableTestResultsPanel() {
    return this.context.is_reviewer || !this.props.enable_test;
  }

  disableFeedbackFilesPanel() {
    return this.context.is_reviewer || this.props.feedback_files.length === 0;
  }

  disableRemarkPanel() {
    if (this.context.is_reviewer || !this.props.allow_remarks) {
      return true;
    } else if (this.props.student_view) {
      return false;
    } else if (this.props.remark_submitted) {
      return false;
    } else {
      return true;
    }
  }

  // Display a given file. Used to changes files from the annotations panel.
  selectFile = (file, submission_file_id, focus_line, annotation_focus) => {
    this.submissionFilePanel.current.selectFile(
      file,
      submission_file_id,
      focus_line,
      annotation_focus
    );
    this.setState({tabIndex: 0}); // Switch to Submission Files tab
  };

  render() {
    return (
      <Tabs
        selectedIndex={this.getSelectedTabIndex()}
        onSelect={tabIndex => this.setState({tabIndex})}
      >
        <TabList>
          <Tab>{I18n.t("activerecord.attributes.submission.submission_files")}</Tab>
          <Tab>{I18n.t("activerecord.models.annotation.other")}</Tab>
          <Tab disabled={this.disableTestResultsPanel()}>
            {I18n.t("activerecord.models.test_result.other")}
          </Tab>
          <Tab disabled={this.disableFeedbackFilesPanel()}>
            {I18n.t("activerecord.attributes.submission.feedback_files")}
          </Tab>
          <Tab disabled={this.disableRemarkPanel()}>
            {I18n.t("activerecord.attributes.submission.submitted_remark")}
          </Tab>
        </TabList>
        <TabPanel forceRender={true}>
          <SubmissionFilePanel
            ref={this.submissionFilePanel}
            result_id={this.context.result_id}
            submission_id={this.context.submission_id}
            assignment_id={this.context.assignment_id}
            grouping_id={this.context.grouping_id}
            revision_identifier={this.props.revision_identifier}
            show_annotation_manager={!this.props.released_to_students}
            canDownload={
              this.context.is_reviewer === undefined ? undefined : !this.context.is_reviewer
            }
            fileData={this.props.submission_files}
            annotation_categories={this.props.annotation_categories}
            annotations={this.props.annotations}
            newAnnotation={this.props.newAnnotation}
            addExistingAnnotation={this.props.addExistingAnnotation}
            released_to_students={this.props.released_to_students}
            loading={this.props.loading}
            course_id={this.context.course_id}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        </TabPanel>
        <TabPanel forceRender={true}>
          <div id="annotations_summary">
            <AnnotationPanel
              detailed={this.props.detailed_annotations}
              released_to_students={this.props.released_to_students}
              overallComment={this.props.overall_comment || ""}
              updateOverallComment={this.props.update_overall_comment}
              remarkSubmitted={this.props.remark_submitted}
              annotations={this.props.annotations}
              editAnnotation={this.props.editAnnotation}
              removeAnnotation={this.props.removeAnnotation}
              selectFile={this.selectFile}
            />
          </div>
        </TabPanel>
        <TabPanel forceRender={!this.disableTestResultsPanel()}>
          <div id="testviewer">
            {/* student results page (with instructor tests released) does not need the button */}
            {!this.props.student_view && (
              <div className="rt-action-box">
                <form
                  method="post"
                  data-remote="true"
                  action={Routes.run_tests_course_result_path(
                    this.context.course_id,
                    this.context.result_id
                  )}
                >
                  <button type="submit" disabled={!this.props.can_run_tests}>
                    <FontAwesomeIcon icon="fa-solid fa-rocket" />
                    {I18n.t("automated_tests.run_tests")}
                  </button>
                  <input type="hidden" name="authenticity_token" value={AUTH_TOKEN} />
                </form>
              </div>
            )}

            <TestRunTable
              result_id={this.context.result_id}
              course_id={this.context.course_id}
              assignment_id={this.context.assignment_id}
              grouping_id={this.context.grouping_id}
              submission_id={this.context.submission_id}
              instructor_run={this.props.instructor_run}
              instructor_view={!this.props.student_view}
              rmd_convert_enabled={this.props.rmd_convert_enabled}
            />
          </div>
        </TabPanel>
        <TabPanel forceRender={!this.disableFeedbackFilesPanel()}>
          <FeedbackFilePanel
            feedbackFiles={this.props.feedback_files}
            loading={this.props.loading}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        </TabPanel>
        <TabPanel forceRender={!this.disableRemarkPanel()}>
          <div id="remark_request_tab">
            <RemarkPanel
              assignmentRemarkMessage={this.props.assignment_remark_message}
              updateOverallComment={this.props.update_overall_comment}
              remarkDueDate={this.props.remark_due_date}
              pastRemarkDueDate={this.props.past_remark_due_date}
              remarkRequestText={this.props.remark_request_text || ""}
              remarkRequestTimestamp={this.props.remark_request_timestamp}
              released_to_students={this.props.released_to_students}
              remarkSubmitted={this.props.remark_submitted}
              overallComment={this.props.remark_overall_comment || ""}
              studentView={this.props.student_view}
            />
          </div>
        </TabPanel>
      </Tabs>
    );
  }
}
