import React from 'react'
import { render } from 'react-dom'
import { SubmissionFileManager } from './submission_file_manager'


class RepoBrowser extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      revision_identifier: props.collected_revision_id,
      revisions: []
    };
  }

  componentDidMount() {
    this.fetchRevisions();
  }

  // Update the list of revisions and set the currently-viewed revision to the most recent one.
  fetchRevisions = () => {
    fetch(
      Routes.revisions_assignment_submissions_path({
        assignment_id: this.props.assignment_id,
        grouping_id: this.props.grouping_id
      }),
      {
        credentials: 'same-origin',
        headers: {
          'content-type': 'application/json'
        }
      }
    ).then(data => data.json())
     .then(data => this.setState({revisions: data, revision_identifier: data[0].id}));
  };

  selectRevision = event => {
    this.setState({revision_identifier: event.target.value});
  };

  revisionToOption = rev => {
    let text = `${rev.id_ui} `;
    if (rev.timestamp !== rev.server_timestamp) {
      text += `(${I18n.t('submissions.repo_browser.client_time')} ${rev.timestamp}, ` +
              `${I18n.t('submissions.repo_browser.server_time')} ${rev.server_timestamp})`;
    } else {
      text += `(${rev.timestamp})`;
    }

    // Highlight the collected revision
    let className = '';
    if (rev.id === this.props.collected_revision_id) {
      className = 'collected';
      text += ` — ${I18n.t('submissions.repo_browser.collected')}`;
    } else {
      className = 'uncollected';
    }

    return <option className={className} key={rev.id} value={rev.id}>{text}</option>;
  };

  render() {
    let className = '';
    if (this.state.revision_identifier === this.props.collected_revision_id) {
      className = 'collected-checked';
    }
    return (
      <div>
        <h3>
          <label>{I18n.t('submissions.repo_browser.viewing_revision')}</label>
          <select
            value={this.state.revision_identifier}
            onChange={this.selectRevision}
            className={className}
          >
            {this.state.revisions.map(this.revisionToOption)}
          </select>
        </h3>
        <SubmissionFileManager
          assignment_id={this.props.assignment_id}
          grouping_id={this.props.grouping_id}
          revision_identifier={this.state.revision_identifier}
          onChange={this.fetchRevisions}
        />
        <ManualCollectionForm
          assignment_id={this.props.assignment_id}
          grouping_id={this.props.grouping_id}
          revision_identifier={this.state.revision_identifier}
        />
      </div>
    )
  }
}


class ManualCollectionForm extends React.Component {
  render() {
    const action = Routes.manually_collect_and_begin_grading_assignment_submission_path(
      this.props.assignment_id,
      this.props.grouping_id
    );

    return (
      <fieldset>
        <legend><span>{I18n.t('submissions.collect.manual_collection')}</span></legend>
      <form
        method="POST"
        action={action}
      >
        <input type="hidden"
               name="current_revision_identifier"
               value={this.props.revision_identifier} />
        <input type="hidden"
               name="authenticity_token"
               value={AUTH_TOKEN} />
        <p>
          <input type="checkbox" name="apply_late_penalty" id="apply_late_penalty" />
          <label htmlFor="apply_late_penalty">{I18n.t('submissions.collect.apply_late_penalty')}</label>
        </p>
        <input type="submit"
               name="commit"
               value={I18n.t('submissions.collect.this_revision')}
               onClick={(event) => {
                 if (!confirm(I18n.t('submissions.collect.overwrite_warning'))) {
                   event.preventDefault();
                 }
               }} />
      </form>
      </fieldset>
    );
  }
}


export function makeRepoBrowser(elem, props) {
  render(<RepoBrowser {...props} />, elem);
}
