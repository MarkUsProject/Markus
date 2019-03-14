import React from 'react';
import { render } from 'react-dom';


class SubmissionSelector extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      marks: [],
    };
  }

  componentDidMount() {
    this.fetchData();
    window.modalNotesGroup = new ModalMarkus('#notes_dialog');
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
      this.setState({...res});
    });
  };

  newNote = () => {
    $.ajax({
      url: Routes.notes_dialog_note_path({
        id: this.props.assignment_id,
      }),
      data: {
        noteable_id: this.props.grouping_id,
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

  toggleMarkingState = () => {
    $.ajax({
      url: Routes.toggle_marking_state_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      method: 'POST',
    }).then(this.fetchData);
  };

  setReleasedToStudents = () => {
    $.ajax({
      url: Routes.set_released_to_students_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      method: 'POST',
    }).then(() => {
      // TODO: Refresh React components without doing a full page refresh
      window.location.reload()
    });
  };

  renderToggleMarkingStateButton = () => {
    let buttonText, disabled;
    if (this.state.marking_state === 'complete') {
      buttonText = I18n.t('results.set_to_incomplete');
      disabled = this.state.released_to_students;
    } else {
      buttonText = I18n.t('results.set_to_complete');
      disabled = this.state.marks.some(mark =>
        mark['marks.mark'] === null || mark['marks.mark'] === undefined
      );
    }
    return (
      <button
        onClick={this.toggleMarkingState}
        disabled={disabled}
      >
        {buttonText}
      </button>
    );
  };

  renderReleaseMarksButton() {
    if (this.props.role !== 'Admin') return '';

    let buttonText, disabled;
    if (this.state.released_to_students) {
      buttonText = I18n.t('submissions.unrelease_marks');
      disabled = false;
    } else {
      buttonText = I18n.t('submissions.release_marks');
      disabled = this.state.marking_state !== 'complete';
    }
    return (
      <button
        onClick={this.setReleasedToStudents}
        disabled={disabled}
      >
        {buttonText}
      </button>
    );
  };

  render() {
    if (this.props.role === 'Student' && !this.state.is_reviewer) {
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
          {!this.state.is_reviewer &&
           <span>
             <a onClick={this.newNote}>
               {I18n.t('activerecord.models.note.other')} ({this.state.notes_count})
             </a>
             &nbsp;|&nbsp;
           </span>
          }
          <em>{I18n.t('activerecord.attributes.result.total_mark')}</em>:&nbsp;
          {this.state.total} / {this.state.assignment_max_mark}
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

export function makeSubmissionSelector(elem, props) {
  return render(<SubmissionSelector {...props} />, elem);
}
