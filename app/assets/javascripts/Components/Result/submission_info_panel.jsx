import React from 'react';


export class SubmissionInfoPanel extends React.Component {
  static defaultProps = {
    availableTags: [],
    currentTags: []
  };

  renderTagList = () => {
    if (this.props.currentTags.length === 0) {
      return I18n.t('tags.results.no_current_tags');
    } else {
      return this.props.currentTags.map(tag => {
        return (
          <li className='active-tag'
                key={tag.id}
                onClick={() => this.props.removeTag(tag.id)}
          >
            {tag.name}
          </li>
        );
      });
    }
  };

  renderAvailableTags = () => {
    if (this.props.availableTags.length === 0) {
      return I18n.t('tags.results.no_available_tags');
    } else {
      return this.props.availableTags.map(tag => {
        return (
          <li className='active-tag'
                key={tag.id}
                onClick={() => this.props.addTag(tag.id)}
          >
            {tag.name}
          </li>
        );
      });
    }
  };

  render() {
    return (
      <div className='pane-body-padding'>
        {this.props.members.length > 0 &&
          <React.Fragment>
            <h3>{I18n.t('activerecord.attributes.group.student_memberships')}</h3>
            <p>{this.props.members.join(', ')}</p>
          </React.Fragment>
        }
        <h3>{I18n.t('tags.results.current_tags')}</h3>
        <ul className='tag-list'>{this.renderTagList()}</ul>
        <h3>{I18n.t('tags.results.available_tags')}</h3>
        <ul className='tag-list'>{this.renderAvailableTags()}</ul>
        {this.props.role === 'Admin' &&
          <p>
            <button className='inline-button' onClick={() => modal_create_new_tag.open()}>
              {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.tag.one')})}
            </button>
          </p>
        }
        <h3>{I18n.t('other_info')}</h3>
        <p>
          <a onClick={this.props.newNote}>
            {I18n.t('activerecord.models.note.other')} ({this.props.notes_count})
          </a>
        </p>
        <p>
          <a href={Routes.repo_browser_assignment_submission_path(this.props.assignment_id, this.props.grouping_id)}>
            {I18n.t('results.view_group_repo')}
          </a>
        </p>
      </div>
    );
  }
}
