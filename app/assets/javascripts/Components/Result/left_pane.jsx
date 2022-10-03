import React from "react";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

import {AnnotationPanel} from "./annotation_panel";
import {FeedbackFilePanel} from "./feedback_file_panel";
import {RemarkPanel} from "./remark_panel";
import {SubmissionFilePanel} from "./submission_file_panel";
import {TestRunTable} from "../test_run_table";

export class LeftPane extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tabIndex: 0,
    };
    this.submissionFilePanel = React.createRef();
  }

  static getDerivedStateFromProps(props, state) {
    // Reset selected tab state if props are changed and a tab becomes disabled.
    // Affected tabs are "Test Results" (tabIndex 2), "Feedback Files" (tabIndex 3),
    // and "Remark Request" (tabIndex 4).
    if (
      (state.tabIndex === 2 && LeftPane.disableTestResultsPanel(props)) ||
      (state.tabIndex === 3 && LeftPane.disableFeedbackFilesPanel(props)) ||
      (state.tabIndex === 4 && LeftPane.disableRemarkPanel(props))
    ) {
      return {tabIndex: 0};
    } else {
      return null;
    }
  }

  static disableTestResultsPanel(props) {
    return props.is_reviewer || !props.enable_test;
  }

  static disableFeedbackFilesPanel(props) {
    return props.is_reviewer || props.feedback_files.length === 0;
  }

  static disableRemarkPanel(props) {
    if (props.is_reviewer || !props.allow_remarks) {
      return true;
    } else if (props.student_view) {
      return false;
    } else if (props.remark_submitted) {
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
      annotation_focus,
    );
    this.setState({tabIndex: 0}); // Switch to Submission Files tab
  };

  render() {
    return (
      <Tabs selectedIndex={this.state.tabIndex} onSelect={tabIndex => this.setState({tabIndex})}>
        <TabList>
          <Tab>{I18n.t("activerecord.attributes.submission.submission_files")}</Tab>
          <Tab>{I18n.t("activerecord.models.annotation.other")}</Tab>
          <Tab disabled={LeftPane.disableTestResultsPanel(this.props)}>
            {I18n.t("activerecord.models.test_result.other")}
          </Tab>
          <Tab disabled={LeftPane.disableFeedbackFilesPanel(this.props)}>
            {I18n.t("activerecord.attributes.submission.feedback_files")}
          </Tab>
          <Tab disabled={LeftPane.disableRemarkPanel(this.props)}>
            {I18n.t("activerecord.attributes.submission.submitted_remark")}
          </Tab>
        </TabList>
        <TabPanel forceRender={true}>
          <SubmissionFilePanel
            ref={this.submissionFilePanel}
            result_id={this.props.result_id}
            submission_id={this.props.submission_id}
            assignment_id={this.props.assignment_id}
            grouping_id={this.props.grouping_id}
            revision_identifier={this.props.revision_identifier}
            show_annotation_manager={!this.props.released_to_students}
            canDownload={this.props.is_reviewer === undefined ? undefined : !this.props.is_reviewer}
            fileData={this.props.submission_files}
            annotation_categories={this.props.annotation_categories}
            annotations={this.props.annotations}
            newAnnotation={this.props.newAnnotation}
            addExistingAnnotation={this.props.addExistingAnnotation}
            released_to_students={this.props.released_to_students}
            loading={this.props.loading}
            course_id={this.props.course_id}
          />
        </TabPanel>
        <TabPanel forceRender={true}>
          <div id="annotations_summary">
            <AnnotationPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              detailed={this.props.detailed_annotations}
              released_to_students={this.props.released_to_students}
              overallComment={this.props.overall_comment || ""}
              updateOverallComment={this.props.update_overall_comment}
              remarkSubmitted={this.props.remark_submitted}
              annotations={this.props.annotations}
              editAnnotation={this.props.editAnnotation}
              removeAnnotation={this.props.removeAnnotation}
              selectFile={this.selectFile}
              course_id={this.props.course_id}
            />
          </div>
        </TabPanel>
        <TabPanel forceRender={!LeftPane.disableTestResultsPanel(this.props)}>
          <div id="testviewer">
            {/* student results page (with instructor tests released) does not need the button */}
            {!this.props.student_view && (
              <div className="rt-action-box">
                <form
                  method="post"
                  data-remote="true"
                  action={Routes.run_tests_course_result_path(
                    this.props.course_id,
                    this.props.result_id,
                  )}
                >
                  <input
                    type="submit"
                    value={I18n.t("automated_tests.run_tests")}
                    disabled={!this.props.can_run_tests}
                  />
                  <input type="hidden" name="authenticity_token" value={AUTH_TOKEN} />
                </form>
              </div>
            )}

            <TestRunTable
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              grouping_id={this.props.grouping_id}
              instructor_run={this.props.instructor_run}
              instructor_view={!this.props.student_view}
              course_id={this.props.course_id}
            />
          </div>
        </TabPanel>
        <TabPanel forceRender={!LeftPane.disableFeedbackFilesPanel(this.props)}>
          <FeedbackFilePanel
            assignment_id={this.props.assignment_id}
            feedbackFiles={this.props.feedback_files}
            submission_id={this.props.submission_id}
            course_id={this.props.course_id}
            loading={this.props.loading}
          />
        </TabPanel>
        <TabPanel forceRender={!LeftPane.disableRemarkPanel(this.props)}>
          <div id="remark_request_tab">
            <RemarkPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
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
              course_id={this.props.course_id}
            />
          </div>
        </TabPanel>
      </Tabs>
    );
  }
}
