import React from 'react';
import { render } from 'react-dom';


export class SubmissionSelector extends React.Component {
  renderToggleMarkingStateButton = () => {
    let buttonText, className, disabled;
    if (this.props.marking_state === 'complete') {
      buttonText = I18n.t('results.set_to_incomplete');
      className = 'set-incomplete';
      disabled = this.props.released_to_students;
    } else {
      buttonText = I18n.t('results.set_to_complete');
      className = 'set-complete';
      disabled = this.props.marks.some(mark =>
        mark['marks.mark'] === null || mark['marks.mark'] === undefined
      );
    }
    return (
      <button
        onClick={this.props.toggleMarkingState}
        className={className}
        disabled={disabled}
        style={{alignSelf: 'flex-end', width: '140px'}}
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
        className='release'
        onClick={this.props.setReleasedToStudents}
        disabled={disabled}
        style={{alignSelf: 'flex-end'}}
      >
        {buttonText}
      </button>
    );
  };

  renderFullscreenButton() {
    if (this.props.fullscreen) {
      return (
        <button className="fullscreen-exit"
                onClick={this.props.toggleFullscreen}
                style={{alignSelf: 'flex-end'}}
        >
          {I18n.t('results.fullscreen_exit')}
        </button>
      );
    } else {
      return (
        <button className="fullscreen-enter"
                onClick={this.props.toggleFullscreen}
                style={{alignSelf: 'flex-end'}}
        >
          {I18n.t('results.fullscreen_enter')}
        </button>
      );
    }
  };

  render() {
    if (this.props.role === 'Student' && !this.props.is_reviewer) {
      return '';
    }

    const url = Routes.next_grouping_assignment_submission_result_path(
      this.props.assignment_id, this.props.submission_id, this.props.result_id
    );

    const progressBarWidth = this.props.num_assigned > 0 ? this.props.num_marked/this.props.num_assigned : 1;
    let progressBarColour;
    if (progressBarWidth > 0.75) {
      progressBarColour = 'green';
    } else if (progressBarWidth > 0.35) {
      progressBarColour = '#FBC02D';
    } else {
      progressBarColour = '#FE2A2A';
    }

    return (
      <div id='submission-selector-container'>
        <div id={'submission-selector'}>
          <a
            className='button previous'
            href={`${url}?direction=-1`}>
            {I18n.t('results.previous_submission')}
          </a>
          <h2 className='group-name' title={this.props.group_name}>
            {this.props.group_name}
          </h2>
          <a
            className='button next'
            href={`${url}?direction=1`}>
            {I18n.t('results.next_submission')}
          </a>
          <div className='progress'>
            <meter
              value={this.props.num_marked}
              min={0}
              max={this.props.num_assigned}
              low={this.props.num_assigned * 0.35}
              high={this.props.num_assigned * 0.75}
              optimum={this.props.num_assigned}
            >
              {this.props.num_marked}/{this.props.num_assigned}
            </meter>
            {this.props.num_marked}/{this.props.num_assigned}&nbsp;{I18n.t('results.state.complete')}
          </div>

          <div style={{flexGrow: 1}} />
          <h2 className='total'>{+(Math.round(this.props.total * 100) / 100)} / {+(this.props.assignment_max_mark)}</h2>
          {this.renderToggleMarkingStateButton()}
          {this.renderReleaseMarksButton()}
          {this.renderFullscreenButton()}
        </div>
      </div>
    );
  }
}
