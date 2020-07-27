import React from 'react';
import { render } from 'react-dom';


export class TagsPanel extends React.Component {
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
          <span className='tag-element'
                key={tag.id}
                onClick={() => this.props.removeTag(tag.id)}
          >
            {tag.name}
          </span>
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
          <span className='tag-element'
                key={tag.id}
                onClick={() => this.props.addTag(tag.id)}
          >
            {tag.name}
          </span>
        );
      });
    }
  };

  render() {
    return (
      <div>
        <h4>{I18n.t('tags.results.current_tags')}</h4>
        <p>{this.renderTagList()}</p>
        {!this.props.remark_submitted &&
         (<div>
           <h4>{I18n.t('tags.results.available_tags')}</h4>
           <p>{this.renderAvailableTags()}</p>
          </div>)
        }
        {!this.props.remark_submitted && this.props.role === 'Admin' &&
         <button className='inline-button' onClick={() => modal_create_new_tag.open()}>
           {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.tag.one')})}
         </button>
        }
        <p>
          <a onClick={this.props.newNote}>
            {I18n.t('activerecord.models.note.other')} ({this.props.notes_count})
          </a>
        </p>
      </div>
    );
  }
}
