import React from 'react';
import { render } from 'react-dom';


export class SubmissionSelector extends React.Component {
  renderToggleMarkingStateButton = () => {
    let buttonText, disabled;
    if (this.props.marking_state === 'complete') {
      buttonText = I18n.t('results.set_to_incomplete');
      disabled = this.props.released_to_students;
    } else {
      buttonText = I18n.t('results.set_to_complete');
      disabled = this.props.marks.some(mark =>
        mark['marks.mark'] === null || mark['marks.mark'] === undefined
      );
    }
    return (
      <button
        onClick={this.props.toggleMarkingState}
        disabled={disabled}
      >
        {buttonText}
      </button>
    );
  };

  renderReleaseMarksButton() {
    if (this.props.role !== 'Admin') return '';

    let buttonText, disabled;
    if (this.props.released_to_students) {
      buttonText = I18n.t('submissions.unrelease_marks');
      disabled = false;
    } else {
      buttonText = I18n.t('submissions.release_marks');
      disabled = this.props.marking_state !== 'complete';
    }
    return (
      <button
        onClick={this.props.setReleasedToStudents}
        disabled={disabled}
      >
        {buttonText}
      </button>
    );
  };

  render() {
    if (this.props.role === 'Student' && !this.props.is_reviewer) {
      return '';
    }

    const url = Routes.next_grouping_assignment_submission_result_path(
      this.props.assignment_id, this.props.submission_id, this.props.result_id
    );

    return (
      <div id={'submission-selector'}>
        <div className='left'>
          <a href={`${url}?direction=-1`}>
            {I18n.t('results.previous_submission')}
          </a>
        </div>
        <div className='middle'>
          {!this.props.is_reviewer &&
           <span>
             <a onClick={this.props.newNote}>
               {I18n.t('activerecord.models.note.other')} ({this.props.notes_count})
             </a>
             &nbsp;|&nbsp;
           </span>
          }
          <em>{I18n.t('activerecord.attributes.result.total_mark')}</em>:&nbsp;
          {this.props.total} / {this.props.assignment_max_mark}
          &nbsp;|&nbsp;
          {this.renderToggleMarkingStateButton()}
          &nbsp;
          {this.renderReleaseMarksButton()}
        </div>
        <div className='right'>
          <a href={`${url}?direction=1`}>
            {I18n.t('results.next_submission')}
          </a>
        </div>
      </div>
    );
  }
}
