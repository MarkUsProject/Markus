import React from 'react';
import { render } from 'react-dom';

import { LeftPane } from './left_pane';
import { RightPane } from './right_pane';
import { SubmissionSelector } from './submission_selector';
import CreateModifyAnnotationPanel from '../Modals/create_modify_annotation_panel_modal';

const INITIAL_ANNOTATION_MODAL_STATE = {
  show: false,
  onSubmit: null,
  title: '',
  content: '',
  categoryId: '',
  isNew: true,
  changeOneOption: false,
};

class Result extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      annotation_categories: [],
      loading: true,
      feedback_files: [],
      submission_files: {files: [], directories: {}, name: '', path: []},
      fullscreen: false,
      annotationModal: INITIAL_ANNOTATION_MODAL_STATE,
      assignment_id: props.assignment_id,
      submission_id: props.submission_id,
      result_id: props.result_id,
      grouping_id: props.grouping_id,
    };

    this.leftPane = React.createRef();
  }

  componentDidMount() {
    this.fetchData();
    window.modal = new ModalMarkus('#annotation_dialog');
    window.modalNotesGroup = new ModalMarkus('#notes_dialog');
    window.modal_create_new_tag = new ModalMarkus('#create_new_tag');

    document.addEventListener('fullscreenchange', () => {
      this.setState({fullscreen: !!document.fullscreenElement}, fix_panes);
    });
  }

  componentDidUpdate(prevProps, prevState) {
    if (this.state.result_id !== prevState.result_id) {
      this.componentDidMount();
    }
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.state.assignment_id,
        this.state.submission_id,
        this.state.result_id
      ),
      dataType: 'json'
    }).then(res => {
      if (res.submission_files) {
        res.submission_files = this.processSubmissionFiles(res.submission_files);
      }
      const markData = this.processMarks(res);
      this.setState({...res, ...markData, loading: false}, () => {
        initializePanes();
        fix_panes();
        this.updateContextMenu();
      });
    });
  };

  /* Processing result data */
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

  processMarks = (result_data) => {
    let criterionSummaryData = [];
    let subtotal = 0;
    let extraMarkSubtotal = 0;
    result_data.marks.forEach(data => {
      data.max_mark = parseFloat(data.max_mark);
      criterionSummaryData.push({
        criterion: data.bonus ? data.name + ' (' + I18n.t('activerecord.attributes.criterion.bonus') + ')' : data.name,
        mark: data.mark,
        old_mark: result_data.old_marks[data.id],
        max_mark: data.max_mark
      });
      subtotal += data.mark || 0;
    });
    result_data.extra_marks.forEach(data => {
      if (data.unit === 'points') {
        extraMarkSubtotal += data.extra_mark;
      } else { // Percentage
        extraMarkSubtotal += data.extra_mark * result_data.assignment_max_mark / 100;
      }
    });
    return {criterionSummaryData, subtotal, extraMarkSubtotal, total: Math.max(subtotal + extraMarkSubtotal, 0)};
  };

  /* Interaction with external components/libraries */
  updateContextMenu = () => {
    if (this.state.released_to_students) return;

    window.annotation_context_menu.setup(
      Routes.annotations_path, this.state.result_id,
      this.state.assignment_id,
      Routes.download_assignment_submission_result_path(
        this.state.assignment_id,
        this.state.submission_id,
        this.state.result_id)
    );

    let common_annotations = this.state.annotation_categories.map(annotation_category => {
      let children;
      if (annotation_category.texts.length === 0) {
        children = [{
          title: I18n.t('annotation_categories.no_annotations'),
          action: () => false,
          disabled: true
        }];
      } else {
        children = annotation_category.texts.map(text => {
          let deduction = '';
          if (!!text.deduction) {
            deduction = '-' + text.deduction;
          }
          return {
            title: `${text.content.replace(/\r?\n/gi, ' ')} <span class="red-text">${deduction}</span>`,
            cmd: `annotation_text_${text.id}`,
            action: () => this.addExistingAnnotation(text.id)
          };
        });
      }
      return {
        title: `${annotation_category.annotation_category_name} <kbd>></kbd>`,
        cmd: `annotation_category_${annotation_category.id}`,
        action: () => false,
        children: children
      };
    });

    window.annotation_context_menu.set_common_annotations(common_annotations);
  };

  toggleFullscreen = () => {
    if (!document.fullscreenElement) {
      document.getElementById('content').requestFullscreen();
    } else {
      document.exitFullscreen();
    }
  };

  /* Callbacks for annotations */
  newAnnotation = () => {
    const submission_file_id = this.leftPane.current.submissionFilePanel.current
      .state.selectedFile[1];
    if (submission_file_id === null) return;

    let metadata = {
      submission_file_id: submission_file_id,
      result_id: this.state.result_id,
      assignment_id: this.state.assignment_id,
    };

    metadata = this.extend_with_selection_data(metadata);

    if (!metadata) {
      return;
    }

    let onSubmit = (formData) => {
      let data = { ...formData, ...metadata };
      return $.post({
        url: Routes.annotations_path(),
        data,
      }).then(() =>
        {
          this.setState({
            annotationModal: INITIAL_ANNOTATION_MODAL_STATE
          })
          this.refreshAnnotations();
        }
      ); // Resetting back to original
    };

    this.setState({
      annotationModal: {
        ...this.state.annotationModal,
        show: true,
        onSubmit,
        title: I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        }),
      },
    });
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

  addAnnotation = (annotation, criterion_id = null, mark_value = null,
                   new_subtotal = null, new_total = null, new_num_marked = null) => {
    this.setState({annotations: this.state.annotations.concat([annotation])});

    if (!!criterion_id) {
      let newMarks = [...this.state.marks];
      let i = newMarks.findIndex(m => m.id === criterion_id);
      if (i >= 0) {
        newMarks[i] = {...newMarks[i]};
        newMarks[i].mark = mark_value;
        this.setState({marks: newMarks, subtotal: new_subtotal, total: new_total, num_marked: new_num_marked});
      }
    }

    if (annotation.annotation_category) {
      this.refreshAnnotationCategories();
    }
  };

  addExistingAnnotation = (annotation_text_id) => {
    const submission_file_id = this.leftPane.current.submissionFilePanel.current.state.selectedFile[1];
    if (submission_file_id === null) {
      return;
    }

    let data = {
      submission_file_id: submission_file_id,
      annotation_text_id: annotation_text_id,
      result_id: this.state.result_id
    };

    data = this.extend_with_selection_data(data);
    if (data) {
      $.post(Routes.add_existing_annotation_annotations_path(), data);
    }
  };

  refreshAnnotationCategories = () => {
    $.get({
      url: Routes.assignment_annotation_categories_path(
        this.state.assignment_id,
      ),
      dataType: 'json'
    }).then(res => {
      this.setState({annotation_categories: res});
    });
  };

  refreshAnnotations = () => {
    $.ajax({
      url: Routes.get_annotations_assignment_submission_result_path(
        this.state.assignment_id,
        this.state.submission_id,
        this.state.result_id),
      dataType: 'json',
    }).then(res => {
      this.setState({annotations: res})
    });
  };

  editAnnotation = (annot_id) => {
    let metadata = {
      result_id: this.state.result_id,
      assignment_id: this.state.assignment_id,
    };

    let onSubmit = (formData) => {
      let data = { ...formData, ...metadata };
      $.ajax({
        url: Routes.annotation_path(annot_id),
        data,
        method: "PUT",
        dataType: "json",
      }).always(() =>
        {
          this.setState({
            annotationModal: INITIAL_ANNOTATION_MODAL_STATE
          })
          this.refreshAnnotations();
        }
      );
    };

    let annotation = this.state.annotations.find(
      (annotation) => annotation.id === parseInt(annot_id, 10)
    );

    let category_id = annotation.annotation_category_id ? annotation.annotation_category_id : "";

    this.setState({
      annotationModal: {
        ...this.state.annotationModal,
        show: true,
        content: annotation.content,
        category_id,
        isNew: false,
        changeOneOption: annotation.annotation_category_id && !annotation.deduction,
        onSubmit,
        title: I18n.t("helpers.submit.create", {
          model: I18n.t("activerecord.models.annotation.one"),
        }),
      },
    });
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
        newAnnotations[i].annotation_category = annotation.annotation_category;
        newAnnotations[i].annotation_text_id = annotation.annotation_text_id;
        this.setState({annotations: newAnnotations});
      }
    }
    update_annotation_text(annotation.annotation_text_id, annotation.content, annotation.id);
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
      url: Routes.annotation_path(annot_id),
      method: 'DELETE',
      data: {
        result_id: this.state.result_id,
        assignment_id: this.state.assignment_id
      },
      dataType: 'script'
    }).then(this.fetchData)
  };

  /* Callbacks for RightPane */
  updateMark = (criterion_id, mark) => {
    if (this.state.released_to_students ||
        (this.state.assigned_criteria !== null &&
         !this.state.assigned_criteria.includes(criterion_id))) {
      return;
    }

    return $.ajax({
      url: Routes.update_mark_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'PATCH',
      data: {
        criterion_id: criterion_id,
        mark: mark
      },
      dataType: 'json'
    }).then(data => {
      let marks = this.state.marks.map(markData => {
        if (markData.id === criterion_id) {
          let newMark = {...markData};
          newMark.mark = data.mark;
          newMark.override = data.mark_override;
          return newMark;
        } else {
          return markData;
        }
      });
      let stateUpdate = { marks, num_marked: data.num_marked, subtotal: data.subtotal, total: data.total };
      if (mark === null) {
        stateUpdate['marking_state'] = 'incomplete';
      }
      this.setState(stateUpdate, () => {
        const newData = this.processMarks(this.state);
        this.setState({...newData});
      });
    });
  };

  destroyMark = (criterion_id) => {
    this.updateMark(criterion_id, null);
  };

  revertToAutomaticDeductions = (criterion_id) => {
    $.ajax({
      url: Routes.revert_to_automatic_deductions_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'PATCH',
      data: {criterion_id: criterion_id}
    }).then(data => {
      let marks = this.state.marks.map(markData => {
        if (markData.id === criterion_id) {
          let newMark = {...markData};
          newMark.mark = data.mark;
          newMark.override = false;
          return newMark;
        } else {
          return markData;
        }
      });
      this.setState({marks: marks, num_marked: data.num_marked, subtotal: data.subtotal, total: data.total});
    });
  };

  createExtraMark = (description, extra_mark) => {
    return $.ajax({
      url: Routes.add_extra_mark_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'POST',
      data: {
        extra_mark: {
          description: description,
          extra_mark: extra_mark
         }
       }
    }).then(this.fetchData)
  };

  destroyExtraMark = (id) => {
    if (!confirm(I18n.t('results.delete_extra_mark_confirm'))) {
      return;
    }

    $.ajax({
      url: Routes.remove_extra_mark_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id,
        // TODO: Fix this route so that the id refers to a Result rather than ExtraMark.
        id
      ),
      method: 'POST',
    }).then(this.fetchData)
  };

  deleteGraceTokenDeduction = (deduction_id) => {
    if (!confirm(I18n.t('grace_period_submission_rules.confirm_remove_deduction'))) {
      return;
    }

    $.ajax({
      url: Routes.delete_grace_period_deduction_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'DELETE',
      data: {deduction_id: deduction_id}
    }).then(this.fetchData)
  };

  addTag = (tag_id) => {
    $.post({
      url: Routes.add_tag_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
  };

  removeTag = (tag_id) => {
    $.post({
      url: Routes.remove_tag_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
  };

  newNote = () => {
    $.ajax({
      url: Routes.notes_dialog_notes_path({
        assignment_id: this.state.assignment_id,
      }),
      data: {
        noteable_id: this.state.grouping_id,
        noteable_type: 'Grouping',
        action_to: 'note_message',
        controller_to: 'results',
        highlight_field: 'notes_dialog_link',
        number_of_notes_field: 'number_of_notes'
      },
      method: 'GET',
      dataType: 'script'
    });
  };

  findDeductiveAnnotation = (file, submission_file_id, focus_line, annotation_id) => {
    this.leftPane.current.selectFile(file, submission_file_id, focus_line, annotation_id);
  };

  /* Callbacks for SubmissionSelector */
  toggleMarkingState = () => {
    $.ajax({
      url: Routes.toggle_marking_state_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'POST',
    }).then(this.fetchData);
  };

  setReleasedToStudents = () => {
    $.ajax({
      url: Routes.set_released_to_students_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      ),
      method: 'POST',
    }).then(() => {
      // TODO: Refresh React components without doing a full page refresh
      window.location.reload()
    });
  };

  nextSubmission = (direction) => {
    return () => {
      const url = Routes.next_grouping_assignment_submission_result_path(
        this.state.assignment_id, this.state.submission_id, this.state.result_id
      );

      $.ajax({
        url: url,
        data: {
          direction: direction
        }
      }).then((result) => {
        if (!result.next_result || !result.next_grouping) {
          alert(I18n.t('results.no_results_in_direction'));
          return;
        }

        const result_obj = {
          result_id: result.next_result.id,
          submission_id: result.next_result.submission_id,
          grouping_id: result.next_grouping.id,
        };
        this.setState(prevState => ({...prevState, ...result_obj}));
        let new_url = Routes.edit_assignment_submission_result_url(
          this.state.assignment_id, this.state.submission_id, this.state.result_id
        );
        history.pushState({}, document.title, new_url)
      })
    }
  }

  render() {
    return [
        <CreateModifyAnnotationPanel
          categories={this.state.annotation_categories}
          onRequestClose={() =>
            this.setState({
              annotationModal: INITIAL_ANNOTATION_MODAL_STATE
            })
          }
          is_reviewer={this.state.is_reviewer}
          assignment_id={this.state.assignment_id}
          {...this.state.annotationModal}
        />,
        <SubmissionSelector
          key='submission-selector'
          role={this.props.role}
          result_id={this.state.result_id}
          submission_id={this.state.submission_id}
          assignment_id={this.state.assignment_id}
          grouping_id={this.state.grouping_id}
          assignment_max_mark={this.state.assignment_max_mark}
          fullscreen={this.state.fullscreen}
          group_name={this.state.group_name}
          is_reviewer={this.state.is_reviewer}
          marks={this.state.marks || []}
          marking_state={this.state.marking_state}
          num_marked={this.state.num_marked}
          num_collected={this.state.num_collected}
          released_to_students={this.state.released_to_students}
          total={this.state.total}
          toggleFullscreen={this.toggleFullscreen}
          toggleMarkingState={this.toggleMarkingState}
          setReleasedToStudents={this.setReleasedToStudents}
          nextSubmission={this.nextSubmission(1)}
          previousSubmission={this.nextSubmission(-1)}
        />,
        <div key='panes-content' id='panes-content'>
          <div id='panes'>
            <div id='left-pane'>
              <LeftPane
                ref={this.leftPane}
                role={this.props.role}
                loading={this.state.loading}
                result_id={this.state.result_id}
                submission_id={this.state.submission_id}
                assignment_id={this.state.assignment_id}
                grouping_id={this.state.grouping_id}
                is_reviewer={this.state.is_reviewer}
                allow_remarks={this.state.allow_remarks}
                annotation_categories={this.state.annotation_categories || []}
                annotations={this.state.annotations || []}
                assignment_remark_message={this.state.assignment_remark_message}
                can_run_tests={this.state.can_run_tests}
                detailed_annotations={this.state.detailed_annotations}
                enable_test={this.state.enable_test}
                feedback_files={this.state.feedback_files}
                instructor_run={this.state.instructor_run}
                overall_comment={this.state.overall_comment}
                past_remark_due_date={this.state.past_remark_due_date}
                released_to_students={this.state.released_to_students}
                remark_due_date={this.state.remark_due_date}
                remark_overall_comment={this.state.remark_overall_comment}
                remark_request_text={this.state.remark_request_text}
                remark_request_timestamp={this.state.remark_request_timestamp}
                remark_submitted={this.state.remark_submitted}
                revision_identifier={this.state.revision_identifier}
                submission_files={this.state.submission_files}
                student_view={this.props.role === 'Student'}
                newAnnotation={this.newAnnotation}
                addAnnotation={this.addAnnotation}
                addExistingAnnotation={this.addExistingAnnotation}
                editAnnotation={this.editAnnotation}
                updateAnnotation={this.updateAnnotation}
                removeAnnotation={this.removeAnnotation}
                destroyAnnotation={this.destroyAnnotation}
              />
            </div>
            <div id='drag'/>
            <div id='right-pane'>
              <RightPane
                assignment_id={this.state.assignment_id}
                submission_id={this.state.submission_id}
                result_id={this.state.result_id}
                grouping_id={this.state.grouping_id}
                role={this.props.role}
                annotations={this.state.annotations}
                assigned_criteria={this.state.assigned_criteria}
                assignment_max_mark={this.state.assignment_max_mark}
                available_tags={this.state.available_tags}
                criterionSummaryData={this.state.criterionSummaryData}
                current_tags={this.state.current_tags}
                extra_marks={this.state.extra_marks}
                extraMarkSubtotal={this.state.extraMarkSubtotal}
                grace_token_deductions={this.state.grace_token_deductions}
                is_reviewer={this.state.is_reviewer}
                marks={this.state.marks}
                notes_count={this.state.notes_count}
                old_marks={this.state.old_marks}
                old_total={this.state.old_total}
                released_to_students={this.state.released_to_students}
                remark_submitted={this.state.remark_submitted}
                revertToAutomaticDeductions={this.revertToAutomaticDeductions}
                subtotal={this.state.subtotal}
                total={this.state.total}
                updateMark={this.updateMark}
                destroyMark={this.destroyMark}
                createExtraMark={this.createExtraMark}
                destroyExtraMark={this.destroyExtraMark}
                deleteGraceTokenDeduction={this.deleteGraceTokenDeduction}
                addTag={this.addTag}
                removeTag={this.removeTag}
                newNote={this.newNote}
                findDeductiveAnnotation={this.findDeductiveAnnotation}
              />
            </div>
          </div>
        </div>
    ];
  }
}


export function makeResult(elem, props) {
  return render(<Result {...props} />, elem);
}
