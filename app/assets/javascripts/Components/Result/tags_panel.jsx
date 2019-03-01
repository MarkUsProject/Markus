import React from 'react';
import { render } from 'react-dom';


export class TagsPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      currentTags: [],
      availableTags: [],
      remark_submitted: false
    };
  }

  componentDidMount() {
    window.modal_create_new_tag = new ModalMarkus('#create_new_tag');
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id),
      dataType: 'json'
    }).then(res => {
      this.setState({
        currentTags: res.current_tags || [],
        availableTags: res.available_tags || [],
        remark_submitted: res.remark_submitted,
      });
    });
  };

  renderTagList = () => {
    if (this.state.currentTags.length === 0) {
      return <span>{I18n.t('tags.results.no_current_tags')}</span>
    } else {
      return this.state.currentTags.map(tag => {
        return (
          <span className='tag_element'
                key={tag.id}
                onClick={() => this.removeTag(tag.id)}
          >
            {tag.name}
          </span>
        );
      });
    }
  };

  renderAvailableTags = () => {
    if (this.state.availableTags.length === 0) {
      return <span>{I18n.t('tags.results.no_available_tags')}</span>;
    } else {
      return this.state.availableTags.map(tag => {
        return (
          <span className='tag_element'
                key={tag.id}
                onClick={() => this.addTag(tag.id)}
          >
            {tag.name}
          </span>
        );
      });
    }
  };

  addTag = (tag_id) => {
    $.post({
      url: Routes.add_tag_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
  };

  removeTag = (tag_id) => {
    $.post({
      url: Routes.remove_tag_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
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
        {!this.state.remark_submitted &&
         (<div>
           <div className={'bonus-deduction'}>
             <strong>{I18n.t('tags.results.available_tags')}</strong>
           </div>
           <div className='tag_collector_pane'>
             {this.renderAvailableTags()}
           </div>
         </div>)
        }
        {!this.state.remark_submitted && this.props.role === 'Admin' &&
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


export function makeTagsPanel(elem, props) {
  return render(<TagsPanel {...props} />, elem);
}

