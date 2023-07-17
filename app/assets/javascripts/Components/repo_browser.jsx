import React from "react";
import {render} from "react-dom";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {SubmissionFileManager} from "./submission_file_manager";

class RepoBrowser extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      revision_identifier: undefined,
      revisions: [],
    };
  }

  componentDidMount() {
    this.fetchRevisions();
  }

  // Update the list of revisions and set the currently-viewed revision to the most recent one.
  fetchRevisions = () => {
    fetch(
      Routes.revisions_course_assignment_submissions_path({
        course_id: this.props.course_id,
        assignment_id: this.props.assignment_id,
        grouping_id: this.props.grouping_id,
      }),
      {
        credentials: "same-origin",
        headers: {
          "content-type": "application/json",
        },
      }
    )
      .then(data => data.json())
      .then(data => this.setState({revisions: data, revision_identifier: data[0].id}));
  };

  selectRevision = event => {
    this.setState({revision_identifier: event.target.value});
  };

  revisionToOption = rev => {
    let text = `${rev.id_ui} `;
    if (rev.timestamp !== rev.server_timestamp) {
      text +=
        `(${I18n.t("submissions.repo_browser.client_time")} ${rev.timestamp}, ` +
        `${I18n.t("submissions.repo_browser.server_time")} ${rev.server_timestamp})`;
    } else {
      text += `(${rev.timestamp})`;
    }

    // Highlight the collected revision
    let className = "";
    if (rev.id === this.props.collected_revision_id) {
      className = "collected";
      text += ` — ${I18n.t("submissions.repo_browser.collected")}`;
    } else {
      className = "uncollected";
    }

    return (
      <option className={className} key={rev.id} value={rev.id}>
        {text}
      </option>
    );
  };

  isReadOnly = () => {
    if (!!this.state.revisions.length) {
      return this.state.revision_identifier !== this.state.revisions[0].id;
    } else {
      return false;
    }
  };

  render() {
    let className = "";
    if (this.state.revision_identifier === this.props.collected_revision_id) {
      className = "collected-checked";
    }
    let manualCollectionForm = "";
    if (this.props.enableCollect) {
      manualCollectionForm = (
        <ManualCollectionForm
          course_id={this.props.course_id}
          assignment_id={this.props.assignment_id}
          late_penalty={this.props.late_penalty}
          grouping_id={this.props.grouping_id}
          revision_identifier={this.state.revision_identifier}
        />
      );
    }
    return (
      <div>
        <h3>
          <label>{I18n.t("submissions.repo_browser.viewing_revision")}</label>
          <select
            value={this.state.revision_identifier}
            onChange={this.selectRevision}
            className={className}
          >
            {this.state.revisions.map(this.revisionToOption)}
          </select>
        </h3>
        {this.props.is_timed && (
          <p>
            <strong>{I18n.t("activerecord.attributes.assignment.start_time")}: </strong>
            {this.props.start_time || I18n.t("not_applicable")}
          </p>
        )}
        <p>
          <strong>{I18n.t("activerecord.attributes.assignment.due_date")}: </strong>
          {this.props.due_date}
        </p>
        <p>
          <strong>{I18n.t("activerecord.attributes.assignment.collection_date")}: </strong>
          {this.props.collection_date}
        </p>
        <SubmissionFileManager
          course_id={this.props.course_id}
          assignment_id={this.props.assignment_id}
          grouping_id={this.props.grouping_id}
          revision_identifier={this.state.revision_identifier}
          onChange={this.fetchRevisions}
          fetchOnMount={false}
          enableSubdirs={this.props.enableSubdirs}
          enableUrlSubmit={this.props.enableUrlSubmit}
          readOnly={this.isReadOnly()}
        />
        {manualCollectionForm}
      </div>
    );
  }
}

class ManualCollectionForm extends React.Component {
  static defaultProps = {
    revision_identifier: "", //set initial value so that the input (in render) remains controlled
  };

  render() {
    const action = Routes.manually_collect_and_begin_grading_course_assignment_submissions_path(
      this.props.course_id,
      this.props.assignment_id
    );

    return (
      <fieldset>
        <legend>
          <span>{I18n.t("submissions.collect.manual_collection")}</span>
        </legend>
        <form method="POST" action={action}>
          <input
            type="hidden"
            name="current_revision_identifier"
            value={this.props.revision_identifier}
          />
          <input type="hidden" name="grouping_id" value={this.props.grouping_id} />
          <input type="hidden" name="authenticity_token" value={AUTH_TOKEN} />
          <p className="inline-labels">
            <input
              hidden={!this.props.late_penalty}
              type="checkbox"
              name="apply_late_penalty"
              id="apply_late_penalty"
            />
            <label hidden={!this.props.late_penalty} htmlFor="apply_late_penalty">
              {I18n.t("submissions.collect.apply_late_penalty")}
            </label>
          </p>
          <button
            type="submit"
            name="commit"
            onClick={event => {
              if (!confirm(I18n.t("submissions.collect.overwrite_warning"))) {
                event.preventDefault();
              }
            }}
          >
            <FontAwesomeIcon icon="fa-solid fa-file-import" />
            {I18n.t("submissions.collect.this_revision")}
          </button>
        </form>
      </fieldset>
    );
  }
}

export function makeRepoBrowser(elem, props) {
  render(<RepoBrowser {...props} />, elem);
}
