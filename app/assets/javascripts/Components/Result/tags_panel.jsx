import React from 'react';
import { render } from 'react-dom';


export class TagsPanel extends React.Component {
  renderTagList = () => {
    if (this.props.currentTags.length === 0) {
      return <span>{I18n.t('tags.results.no_current_tags')}</span>
    } else {
      return this.props.currentTags.map(tag => {
        return (
          <span className='tag_element'
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
      return <span>{I18n.t('tags.results.no_available_tags')}</span>;
    } else {
      return this.props.availableTags.map(tag => {
        return (
          <span className='tag_element'
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
        <div className={'bonus-deduction'}>
          <strong>{I18n.t('tags.results.current_tags')}</strong>
        </div>
        <div className={'tag_collector_pane'}>
          {this.renderTagList()}
        </div>
        {!this.props.remark_submitted &&
         (<div>
           <div className={'bonus-deduction'}>
             <strong>{I18n.t('tags.results.available_tags')}</strong>
           </div>
           <div className='tag_collector_pane'>
             {this.renderAvailableTags()}
           </div>
         </div>)
        }
        {!this.props.remark_submitted && this.props.role === 'Admin' &&
         <div className='tag_admin'>
           <button onClick={() => modal_create_new_tag.open()}>
             {I18n.t('helpers.submit.create', {model: I18n.t('activerecord.models.tag.one')})}
           </button>
         </div>
        }
      </div>
    );
  }
}
