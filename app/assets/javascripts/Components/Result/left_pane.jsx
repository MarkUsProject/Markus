import React from 'react';
import { render } from 'react-dom';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import { AnnotationPanel } from './annotation_panel';
import { FeedbackFilePanel } from './feedback_file_panel';
import { RemarkPanel } from './remark_panel';
import { SubmissionFilePanel } from './submission_file_panel';
import { TestRunTable } from '../test_run_table';


class LeftPane extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      feedback_files: [],
      loading: true
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id
      ),
      dataType: 'json'
    }).then(res => this.setState({...res, loading: false}))
  };

  disableRemarkPanel = () => {
    if (this.state.is_reviewer || !this.state.allow_remarks) {
      return true;
    } else if (this.state.student_view) {
      return false;
    } else if (this.state.remark_submitted) {
      return false;
    } else {
      return true;
    }
  };

  runTests = () => {
    $.post({
      url: Routes.run_tests_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      )
    });
  };

  render() {
    if (this.state.loading) {
      return I18n.t('working');
    }

    return (
      <Tabs>
        <TabList>
          <Tab>{I18n.t('activerecord.attributes.submission.submission_files')}</Tab>
          <Tab>{I18n.t('activerecord.models.annotation.other')}</Tab>
          <Tab disabled={this.state.is_reviewer || !this.state.enable_test}>
            {I18n.t('automated_tests.test_results')}
          </Tab>
          <Tab disabled={this.state.is_reviewer || this.state.feedback_files.length === 0}>
            {I18n.t('activerecord.attributes.submission.feedback_files')}
          </Tab>
          <Tab disabled={this.disableRemarkPanel()}>
            {I18n.t('activerecord.attributes.submission.submitted_remark')}
          </Tab>
        </TabList>
        <TabPanel forceRender={true}>
          <div id='code_pane'>
            <SubmissionFilePanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              grouping_id={this.state.grouping_id}
              revision_identifier={this.state.revision_identifier}
              show_annotation_manager={!this.state.released_to_students && !this.state.is_reviewer}
              canDownload={!this.state.is_reviewer}
            />
          </div>
        </TabPanel>
        <TabPanel forceRender={true}>
          <div id='annotations_summary'>
            <AnnotationPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              detailed={this.state.detailed_annotations}
              released_to_students={this.state.released_to_students}
              overallComment={this.state.overall_comment || ''}
              remarkSubmitted={this.state.remark_submitted}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='testviewer' className='block'>
            <h2 className='test_runs_header'>{I18n.t('automated_tests.test_results')}
              {// student results page (with instructor tests released) does not need the button
               }

              {!this.state.student_view &&
               <form>
                 <button onClick={this.runTests} disabled={!this.state.can_run_tests}>
                   {I18n.t('automated_tests.run_tests')}
                 </button>
               </form>}
            </h2>

            <TestRunTable
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              grouping_id={this.state.grouping_id}
              instructor_run={this.state.instructor_run}
              instructor_view={!this.state.student_view}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='feedback_file_tab'>
            <FeedbackFilePanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              feedbackFiles={this.state.feedback_files}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='remark_request_tab'>
            <RemarkPanel
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              assignmentRemarkMessage={this.state.assignment_remark_message}
              remarkDueDate={this.state.assignment_due_date}
              pastRemarkDueDate={this.state.past_remark_due_date}
              remarkRequestText={this.state.remark_request_text || ''}
              remarkRequestTimestamp={this.state.remark_request_timestamp}
              released_to_students={this.state.released_to_students}
              remarkSubmitted={this.state.remark_submitted}
              overallComment={this.state.remark_overall_comment || ''}
              studentView={this.state.student_view}
            />
          </div>
        </TabPanel>
      </Tabs>
    );
  }
}


export function makeLeftPane(elem, props) {
  render(<LeftPane {...props} />, elem);
}
