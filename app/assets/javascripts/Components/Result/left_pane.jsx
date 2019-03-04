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
      submission_files: {files: [], directories: {}, name: '', path: []},
      annotations: [],
      loading: true,
      tabIndex: 0,
    };
    this.submissionFilePanel = React.createRef();
  }

  componentDidMount() {
    initializePanes();
    this.fetchData();
    window.modal = new ModalMarkus('#annotation_dialog');
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id
      ),
      dataType: 'json'
    }).then(res => {
      if (res.submission_files) {
        res.submission_files = this.processSubmissionFiles(res.submission_files);
      }
      this.setState({...res, loading: false}, fix_panes);
    });
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

  processSubmissionFiles = (data) => {
    let fileData = {files: [], directories: {}, name: '', path: []};
    data.forEach(({id, filename, path}) => {
      // Use .slice(1) to remove the Assignment repository name.
      let segments = path.split('/').concat(filename).slice(1);
      let currHash = fileData;
      segments.forEach((segment, i) => {
        if (i === segments.length - 1) {
          currHash.files.push([segment, id]);
        } else if (currHash.directories.hasOwnProperty(segment)) {
          currHash = currHash.directories[segment];
        } else {
          currHash.directories[segment] = {
            files: [], directories: {}, name: segment,
            path: segments.slice(0, i + 1)
          };
          currHash = currHash.directories[segment];
        }
      })
    });
    return fileData;
  };

  // Callbacks for annotations
  newAnnotation = () => {
    const submission_file_id = this.submissionFilePanel.current.state.selectedFile[1];
    if (submission_file_id === null) {
      return;
    }

    let data = {
      submission_file_id: submission_file_id,
      result_id: this.props.result_id,
      assignment_id: this.props.assignment_id
    };

    data = this.extend_with_selection_data(data);
    if (data) {
      $.get(Routes.new_annotation_path(), data);
    }
  };

  extend_with_selection_data = (annotation_data) => {
    let box;
    if (annotation_type === ANNOTATION_TYPES.IMAGE) {
      box = get_image_annotation_data();
    } else if (annotation_type === ANNOTATION_TYPES.PDF) {
      box = get_pdf_annotation_data();
    } else {
      box = get_text_annotation_data();
    }
    if (box) {
      return Object.assign(annotation_data, box);
    }
  };

  addAnnotation = (annotation) => {
    this.setState({annotations: this.state.annotations.concat([annotation])});

    if (annotation.annotation_category) {
      this.refreshAnnotationCategories();
    }
  };

  addExistingAnnotation = (annotation_text_id) => {
    const submission_file_id = this.submissionFilePanel.current.state.selectedFile[1];
    if (submission_file_id === null) {
      return;
    }

    let data = {
      submission_file_id: submission_file_id,
      annotation_text_id: annotation_text_id,
      result_id: this.props.result_id
    };

    data = this.extend_with_selection_data(data);
    if (data) {
      $.post(Routes.add_existing_annotation_annotations_path(), data);
    }
  };

  refreshAnnotationCategories = () => {
    $.get({
      url: Routes.assignment_annotation_categories_path(
        this.props.assignment_id,
      ),
      dataType: 'json'
    }).then(res => {
      this.setState({annotation_categories: res});
    });
  };

  refreshAnnotations = () => {
    $.ajax({
      url: Routes.get_annotations_assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id),
      dataType: 'json',
    }).then(res => {
      this.setState({annotations: res})
    });
  };

  editAnnotation = (annot_id) => {
    $.ajax({
      url: Routes.edit_annotation_path(annot_id),
      method: 'GET',
      data: {
        result_id: this.props.result_id,
        assignment_id: this.props.assignment_id
      },
      dataType: 'script'
    })
  };

  updateAnnotation = (annotation) => {
    // If the modified text was for a shared annotation, reload all annotations.
    // (This is pretty naive.)
    if (annotation.annotation_category !== '') {
      this.refreshAnnotations();
    } else {
      let newAnnotations = [...this.state.annotations];
      let i = newAnnotations.findIndex(a => a.id === annotation.id);
      if (i >= 0) {
        // Manually copy the annotation.
        newAnnotations[i] = {...newAnnotations[i]};
        newAnnotations[i].content = annotation.content;
        this.setState({annotations: newAnnotations});
      }
    }
    update_annotation_text(annotation.id, marked(annotation.content, {sanitize: true}));
  };

  destroyAnnotation(annotation_id, range, annotation_text_id) {
    remove_annotation(annotation_id, range, annotation_text_id);
    let newAnnotations = [...this.state.annotations];
    const i = newAnnotations.findIndex(a => a.id === annotation_id);
    if (i >= 0) {
      newAnnotations.splice(i, 1);
      this.setState({annotations: newAnnotations});
    }
  }

  removeAnnotation = (annot_id) => {
    $.ajax({
      url: Routes.annotations_path(),
      method: 'DELETE',
      data: {
        id: annot_id,
        result_id: this.props.result_id,
        assignment_id: this.props.assignment_id
      },
      dataType: 'script'
    }).then(this.fetchData)
  };

  // Display a given file. Used to changes files from the annotations panel.
  selectFile = (file, submission_file_id, focus_line) => {
    this.submissionFilePanel.current.selectFile(file, submission_file_id, focus_line);
    this.setState({tabIndex: 0});  // Switch to Submission Files tab
  };

  render() {
    if (this.state.loading) {
      return I18n.t('working');
    }

    return (
      <Tabs selectedIndex={this.state.tabIndex} onSelect={tabIndex => this.setState({tabIndex})}>
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
          <div>
            <SubmissionFilePanel
              ref={this.submissionFilePanel}
              result_id={this.props.result_id}
              submission_id={this.props.submission_id}
              assignment_id={this.props.assignment_id}
              grouping_id={this.state.grouping_id}
              revision_identifier={this.state.revision_identifier}
              show_annotation_manager={!this.state.released_to_students && !this.state.is_reviewer}
              canDownload={!this.state.is_reviewer}
              fileData={this.state.submission_files}
              annotation_categories={this.state.annotation_categories || []}
              annotations={this.state.annotations}
              newAnnotation={this.newAnnotation}
              addExistingAnnotation={this.addExistingAnnotation}
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
              annotations={this.state.annotations}
              editAnnotation={this.editAnnotation}
              removeAnnotation={this.removeAnnotation}
              selectFile={this.selectFile}
            />
          </div>
        </TabPanel>
        <TabPanel>
          <div id='testviewer' className='block'>
            <h2 className='test_runs_header'>
              {I18n.t('automated_tests.test_results')}
              {/* student results page (with instructor tests released) does not need the button */}
              {!this.state.student_view &&
               <form method='post' action={Routes.run_tests_assignment_submission_result_path(
                                             this.props.assignment_id, this.props.submission_id, this.props.result_id)}>
                 <input type="submit" value={I18n.t('automated_tests.run_tests')}
                        disabled={!this.state.can_run_tests} />
                 <input type="hidden" name="authenticity_token" value={AUTH_TOKEN} />
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
              remarkDueDate={this.state.remark_due_date}
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
  return render(<LeftPane {...props} />, elem);
}
