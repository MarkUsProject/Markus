import React from 'react';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import { AnnotationPanel } from './annotation_panel';
import { FeedbackFilePanel } from './feedback_file_panel';
import { RemarkPanel } from './remark_panel';
import { SubmissionFilePanel } from './submission_file_panel';
import { TestRunTable } from '../test_run_table';


export class LeftPane extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tabIndex: 0,
    };
    this.submissionFilePanel = React.createRef();
  }

  disableRemarkPanel = () => {
    if (this.props.is_reviewer || !this.props.allow_remarks) {
      return true;
    } else if (this.props.student_view) {
      return false;
    } else if (this.props.remark_submitted) {
      return false;
    } else {
      return true;
    }
  };

  // Display a given file. Used to changes files from the annotations panel.
  selectFile = (file, submission_file_id, focus_line, annotation_focus) => {
    this.submissionFilePanel.current.selectFile(file, submission_file_id, focus_line, annotation_focus);
    this.setState({tabIndex: 0});  // Switch to Submission Files tab
  };

  render() {
    return (
      <Tabs selectedIndex={this.state.tabIndex} onSelect={tabIndex => this.setState({tabIndex})}>
        <TabList>
          <Tab>{I18n.t('activerecord.attributes.submission.submission_files')}</Tab>
          <Tab>{I18n.t('activerecord.models.annotation.other')}</Tab>
          <Tab disabled={this.props.is_reviewer || !this.props.enable_test}>
            {I18n.t('activerecord.models.test_result.other')}
          </Tab>
          <Tab disabled={this.props.is_reviewer || this.props.feedback_files.length === 0}>
            {I18n.t('activerecord.attributes.submission.feedback_files')}
          </Tab>
          <Tab disabled={this.disableRemarkPanel()}>
            {I18n.t('activerecord.attributes.submission.submitted_remark')}
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
              show_annotation_manager={!this.props.released_to_students && !this.props.is_reviewer}
              canDownload={this.props.is_reviewer === undefined ? undefined : !this.props.is_reviewer}
              fileData={this.props.submission_files}
              annotation_categories={this.props.annotation_categories}
              annotations={this.props.annotations}
              newAnnotation={this.props.newAnnotation}
              addExistingAnnotation={this.props.addExistingAnnotation}
              released_to_students={this.props.released_to_students}
              loading={this.props.loading}
            />
        </TabPanel>
        <TabPanel forceRender={true}>
          <div id='annotations_summary'>
            <AnnotationPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              detailed={this.props.detailed_annotations}
              released_to_students={this.props.released_to_students}
              overallComment={this.props.overall_comment || ''}
              remarkSubmitted={this.props.remark_submitted}
              annotations={this.props.annotations}
              editAnnotation={this.props.editAnnotation}
              removeAnnotation={this.props.removeAnnotation}
              selectFile={this.selectFile}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='testviewer'>
            {/* student results page (with instructor tests released) does not need the button */}
            {!this.props.student_view &&
             <div className='rt-action-box'>
               <form method='post' action={Routes.run_tests_assignment_submission_result_path(
                                             this.props.assignment_id, this.props.submission_id, this.props.result_id)}>
                 <input type="submit" value={I18n.t('automated_tests.run_tests')}
                        disabled={!this.props.can_run_tests} />
                 <input type="hidden" name="authenticity_token" value={AUTH_TOKEN} />
               </form>
             </div>}

            <TestRunTable
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              grouping_id={this.props.grouping_id}
              instructor_run={this.props.instructor_run}
              instructor_view={!this.props.student_view}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='feedback_file_tab'>
            <FeedbackFilePanel
              assignment_id={this.props.assignment_id}
              feedbackFiles={this.props.feedback_files}
              submission_id={this.props.submission_id}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='remark_request_tab'>
            <RemarkPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              assignmentRemarkMessage={this.props.assignment_remark_message}
              remarkDueDate={this.props.remark_due_date}
              pastRemarkDueDate={this.props.past_remark_due_date}
              remarkRequestText={this.props.remark_request_text || ''}
              remarkRequestTimestamp={this.props.remark_request_timestamp}
              released_to_students={this.props.released_to_students}
              remarkSubmitted={this.props.remark_submitted}
              overallComment={this.props.remark_overall_comment || ''}
              studentView={this.props.student_view}
            />
          </div>
        </TabPanel>
      </Tabs>
    );
  }
}
