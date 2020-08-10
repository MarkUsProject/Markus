import React from 'react';
import { render } from 'react-dom';


export class RemarkPanel extends React.Component {
  componentDidMount() {
    if (this.props.released_to_students) {
      const comment = this.props.overallComment;
      let target_id = 'overall_remark_comment';
      document.getElementById(target_id).innerHTML = marked(comment, {sanitize: true});
      MathJax.Hub.Queue(['Typeset', MathJax.Hub, target_id]);
    }
  }

  submitOverallComment = (value) => {
    return $.post({
      url: Routes.update_overall_comment_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id,
      ),
      data: {result: {overall_comment: value}},
    })
  };

  submitRemarkRequest = (value, name) => {
    let data = {submission: {remark_request: value}};
    data[name] = 'true';
    return $.ajax({
      url: Routes.update_remark_request_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.submission_id
      ),
      method: 'PATCH',
      data: data,
    })
  };

  render() {
    const remark_request = marked(this.props.remarkRequestText);

    let remarkCommentElement;
    if (this.props.released_to_students) {
      remarkCommentElement = <div id='overall_remark_comment' />;
    } else {
      remarkCommentElement =
        <TextForm
          initialValue={this.props.overallComment}
          onSubmit={this.submitOverallComment}
          previewId={'overall_remark_comment_preview'}
        />;
    }

    let remarkDueDate;
    if (this.props.remarkDueDate) {
      remarkDueDate = I18n.t('activerecord.attributes.assignment.remark_due_date') + ': ' +
        I18n.l('time.formats.default', this.props.remarkDueDate);
    } else {
      remarkDueDate = I18n.t('results.remark.no_remark_due_date');
    }

    const extraInstructions = <p>
      {I18n.t('results.remark.about_remark_save')}&nbsp;
      {I18n.t('results.remark.about_remark_submission')}&nbsp;
      {I18n.t('results.remark.cancel_remark_to_change')}
    </p>;

    let remarkRequestElement;
    if (this.props.studentView && !this.props.remarkSubmitted) {
      if (this.props.pastRemarkDueDate) {
        remarkRequestElement = I18n.t('results.remark.past_remark_due_date');
      } else {
        remarkRequestElement =
          <RemarkRequestForm
            onSubmit={this.submitRemarkRequest}
            initialValue={this.props.remarkRequestText}
          />;
      }
    } else if (this.props.remarkSubmitted) {
      remarkRequestElement = (
        <div>
          <p>{I18n.t('results.remark.submitted_on',
                     {time: I18n.l('time.formats.default', this.props.remarkRequestTimestamp)})}</p>
          <div dangerouslySetInnerHTML={{__html: remark_request}} />
        </div>
      );
    } else {
      remarkRequestElement = '';
    }

    return (
      <div id='remark_request'>
        <h3>{I18n.t('activerecord.attributes.assignment.remark_message')}</h3>
        <p>{this.props.assignmentRemarkMessage}</p>
        <p>{remarkDueDate}</p>
        {this.props.studentView && extraInstructions}
        <h3>{I18n.t('activerecord.attributes.submission.submitted_remark')}</h3>
        {remarkRequestElement}
        {(!this.props.studentView || this.props.remarkSubmitted) &&
          <h3>{I18n.t('activerecord.attributes.result.overall_comment')}</h3>}
        {remarkCommentElement}
      </div>
    );
  }
}


class TextForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: this.props.initialValue,
      unsavedChanges: false
    };
    this.button = React.createRef();
  }

  componentDidMount() {
    this.updatePreview();
  }

  updateValue = (event) => {
    const value = event.target.value;
    this.setState({value: value, unsavedChanges: true}, this.updatePreview);
  };

  updatePreview = () => {
    if (this.props.previewId) {
      document.getElementById(this.props.previewId).innerHTML = marked(this.state.value, {sanitize: true});
      MathJax.Hub.Queue(['Typeset', MathJax.Hub, this.props.previewId]);
    }
  };

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit(this.state.value)
      .then(() => {
        Rails.enableElement(this.button.current);
        this.setState({unsavedChanges: false});
      });
  };

  render() {
    return (
      <div className={this.props.className || ''}>
        <form onSubmit={this.onSubmit}>
          <textarea
            value={this.state.value}
            onChange={this.updateValue}
            rows={5}
          />
          <p>
            <input type='submit' value={I18n.t('save')}
                   data-disable-with={I18n.t('working')}
                   ref={this.button}
                   disabled={!this.state.unsavedChanges}
            />
          </p>
        </form>
        {this.props.previewId && (
          <div>
            <h3>{I18n.t('preview')}</h3>
            <div id={this.props.previewId} className='preview' />
          </div>
        )}
      </div>
    );
  }
}


class RemarkRequestForm extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      value: this.props.initialValue,
      unsavedChanges: false
    };
    this.button = React.createRef();
  }

  updateValue = (event) => {
    const value = event.target.value;
    this.setState({value: value, unsavedChanges: true});
  };

  onSubmit = (event) => {
    event.preventDefault();
    this.props.onSubmit(this.state.value, event.target.name)
      .then(() => {
        Rails.enableElement(this.button.current);
        this.setState({unsavedChanges: false});
      });
  };

  render() {
    return (
      <div className={this.props.className || ''}>
        <form>
          <textarea
            value={this.state.value}
            onChange={this.updateValue}
            rows={10}
          />
          <p>
            <input type='submit' value={I18n.t('save')}
                   name='save'
                   data-disable-with={I18n.t('working')}
                   ref={this.button}
                   disabled={!this.state.unsavedChanges}
                   onClick={(e) => this.onSubmit(e)}
            />
            <input type='submit' value={I18n.t('results.remark.submit')}
                   name='submit'
                   data-disable-with={I18n.t('working')}
                   data-confirm={I18n.t('results.remark.submit_confirm')}
                   onClick={(e) => this.onSubmit(e)}
            />
          </p>
        </form>
      </div>
    );
  }
}
