import React from 'react';
import {render} from 'react-dom';

import {CheckboxTable, withSelection} from './markus_with_selection_hoc'


class RawSubmissionTable extends React.Component {
  constructor() {
    super();
    this.state = {
      groupings: [],
      sections: {},
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submissions_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.props.resetSelection();
      this.setState({
        groupings: res.groupings,
        sections: res.sections,
        loading: false,
      });
    });
  };

  columns = () => [
    {
      show: false,
      accessor: '_id',
      id: '_id'
    },
    {
      Header: I18n.t('activerecord.models.groups.one'),
      accessor: 'group_name',
      id: 'group_name',
      Cell: row => {
        let members = '';
        if (this.props.show_members) {
          if (row.original.members) {
            members = ` (${row.original.members.join(', ')})`;
          } else {
            members = '';
          }
        }
        if (row.original.result_id) {
          const result_url = Routes.edit_assignment_submission_result_path(
            this.props.assignment_id,
            row.original.result_id,
            row.original.result_id,
          );
          return <a href={result_url}>{row.value + members}</a>;
        } else {
          return row.value + members;
        }
      },
      minWidth: 170,
      filterMethod: (filter, row) => {
        if (filter.value) {
          // Check group name
          if (row._original.group_name.includes(filter.value)) {
            return true;
          }

          // Check member names
          return row._original.members && row._original.members.some(
            (name) => name.includes(filter.value)
          );
        } else {
          return true;
        }
      },
    },
    {
      Header: I18n.t('submissions.repo_browser.repository'),
      filterable: false,
      sortable: false,
      Cell: row => {
        return (
          <a href={Routes.repo_browser_assignment_submission_path(
                     this.props.assignment_id, row.original._id)}
             className={row.original.no_files ? 'no-files' : ''}
          >
            {row.original.group_name}
          </a>
        );
      },
      minWidth: 80,
    },
    {
      Header: I18n.t('activerecord.models.section', {count: 1}),
      accessor: 'section',
      id: 'section',
      show: this.props.show_sections,
      minWidth: 70,
      Cell: ({ value }) => {
        return this.state.sections[value] || ''
      },
      filterMethod: (filter, row) => {
        if (filter.value === 'all') {
          return true;
        } else {
          return this.state.sections[row[filter.id]] === filter.value;
        }
      },
      Filter: ({ filter, onChange }) =>
        <select
          onChange={event => onChange(event.target.value)}
          style={{ width: '100%' }}
          value={filter ? filter.value : 'all'}
        >
          <option value='all'>{I18n.t('all')}</option>
          {Object.entries(this.state.sections).map(
            kv => <option key={kv[1]} value={kv[1]}>{kv[1]}</option>)}
        </select>,
    },
    {
      Header: I18n.t('submissions.commit_date'),
      accessor: 'submission_time',
      filterable: false,
      minWidth: 150,
      sortMethod: (a,b) => {
        if (typeof a === 'string' && typeof b === 'string') {
          let a_date = Date.parse(a);
          let b_date = Date.parse(b);
          return a_date > b_date ? 1 : -1;
        } else {
        return a > b ? 1 : -1;
        }
      }
    },
    {
      Header: I18n.t('submissions.grace_credits_used'),
      accessor: 'grace_credits_used',
      show: this.props.show_grace_tokens,
      minWidth: 100,
      style: { textAlign: 'right' },
    },
    {
      Header: I18n.t('activerecord.attributes.result.marking_state'),
      accessor: 'marking_state',
      filterMethod: (filter, row) => {
        if (filter.value === 'all') {
          return true;
        } else {
          return filter.value === row[filter.id];
        }
      },
      Filter: ({ filter, onChange }) =>
        <select
          onChange={event => onChange(event.target.value)}
          style={{ width: '100%' }}
          value={filter ? filter.value : 'all'}
        >
          <option value='all'>{I18n.t('all')}</option>
          <option value={I18n.t('results.state.not_collected')}>{I18n.t('results.state.not_collected')}</option>
          <option value='incomplete'>{I18n.t('results.state.in_progress')}</option>
          <option value='complete'>{I18n.t('results.state.complete')}</option>
          <option value='released'>{I18n.t('results.state.released')}</option>
          <option value='remark'>{I18n.t('results.state.remark_requested')}</option>
        </select>,
      minWidth: 70
    },
    {
      Header: I18n.t('activerecord.attributes.result.total_mark'),
      accessor: 'final_grade',
      Cell: ({value}) => (value === undefined ? '-' : value) + ' / ' + this.props.max_mark,
      className: 'number',
      minWidth: 80,
      filterable: false,
      defaultSortDesc: true,
    },
    {
      Header: I18n.t('browse_submissions.tags_used'),
      accessor: 'tags',
      Cell: row => (
        <div className="tag_list">
          {row.original.tags.map(tag =>
            <span key={`${row.original._id}-${tag}`}
              className="tag_element">
              {tag}
            </span>
          )}
        </div>
      ),
      minWidth: 80,
      sortable: false
    }
  ];

  // Custom getTrProps function to highlight submissions that have been collected.
  getTrProps = (state, ri, ci, instance) => {
    if (ri.original.marking_state === undefined ||
        ri.original.marking_state === I18n.t('results.state.not_collected')) {
      return {ri};
    } else {
      return {ri, className: 'submission_collected'};
    }
  };

  // Submission table actions
  collectSubmissions = () => {
    if (!window.confirm(I18n.t('submissions.collect.results_loss_warning'))) {
      return;
    }

    $.post({
      url: Routes.collect_submissions_assignment_submissions_path(this.props.assignment_id),
      data: { groupings: this.props.selection },
    });
  };

  uncollectAllSubmissions = () => {
    if (!window.confirm(I18n.t('submissions.collect.undo_results_loss_warning'))) {
      return;
    }

    $.get({
      url: Routes.uncollect_all_submissions_assignment_submissions_path(this.props.assignment_id),
      data: { groupings: this.props.selection },
    });
  };

  downloadGroupingFiles = (event) => {
    if (!window.confirm(I18n.t('submissions.marking_incomplete_warning'))) {
      event.preventDefault();
    }
  };

  runTests = () => {
    $.post({
      url: Routes.run_tests_assignment_submissions_path(this.props.assignment_id),
      data: { groupings: this.props.selection },
    });
  };

  releaseMarks = () => {
    $.post({
      url: Routes.update_submissions_assignment_submissions_path(this.props.assignment_id),
      data: {
        release_results: true,
        groupings: this.props.selection
      }
    }).then(this.fetchData);
  };

  unreleaseMarks = () => {
    $.post({
      url: Routes.update_submissions_assignment_submissions_path(this.props.assignment_id),
      data: {
        release_results: false,
        groupings: this.props.selection
      }
    }).then(this.fetchData);
  };

  render() {
    const { loading } = this.state;

    return (
      <div>
        <SubmissionsActionBox
          ref={(r) => this.actionBox = r}
          disabled={this.props.selection.length === 0}
          is_admin={this.props.is_admin}
          assignment_id={this.props.assignment_id}
          can_run_tests={this.props.can_run_tests}

          collectSubmissions={this.collectSubmissions}
          downloadGroupingFiles={this.downloadGroupingFiles}
          runTests={this.runTests}
          releaseMarks={this.releaseMarks}
          unreleaseMarks={this.unreleaseMarks}
        />
        <CheckboxTable
          ref={(r) => this.checkboxTable = r}

          data={this.state.groupings}
          columns={this.columns()}
          defaultSorted={[
            {
              id: 'group_name'
            }
          ]}
          filterable
          loading={loading}

          getTrProps={this.getTrProps}

          {...this.props.getCheckboxProps()}
          {...this.props.getCheckboxProps}
        />
      </div>
    );
  }
}


let SubmissionTable = withSelection(RawSubmissionTable);
SubmissionTable.defaultProps = {
  is_admin: false,
  can_run_tests: false
};


class SubmissionsActionBox extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      button_disabled: false
    };
  }

  render = () => {
    let collectButton, runTestsButton, releaseMarksButton, unreleaseMarksButton;
    if (this.props.is_admin) {
      collectButton = (
        <button
          onClick={this.props.collectSubmissions}
          disabled={this.props.disabled}
        >
          {I18n.t('submissions.collect.submit')}
        </button>
      );
      // TODO: look into re-enabling undo collection
      // uncollectButton = (
      //   <button onClick={this.props.uncollectSubmissions}
      //           disabled={this.props.disabled}>
      //     {I18n.t('collect_submissions.uncollect_all')}
      //   </button>
      // );

      releaseMarksButton = (
        <button
          disabled={this.props.disabled}
          onClick={this.props.releaseMarks}>
          {I18n.t('submissions.release_marks')}
        </button>
      );
      unreleaseMarksButton = (
        <button
          disabled={this.props.disabled}
          onClick={this.props.unreleaseMarks}>
          {I18n.t('submissions.unrelease_marks')}
        </button>
      );
    }
    if (this.props.can_run_tests) {
      runTestsButton = (
        <button onClick={this.props.runTests}
                disabled={this.props.disabled}
        >
          {I18n.t('submissions.run_tests')}
        </button>
      );
    }

    let downloadGroupingFilesButton = (
      <a
        href={Routes.download_groupings_files_assignment_submissions_path(this.props.assignment_id)}
        onClick={this.props.downloadGroupingFiles}
        download
        className="button"
      >
        {I18n.t('download_the', {item: I18n.t('activerecord.models.submission.other')})}
      </a>
    );

    return (
      <div className='rt-action-box'>
        {collectButton}
        {downloadGroupingFilesButton}
        {runTestsButton}
        {releaseMarksButton}
        {unreleaseMarksButton}
      </div>
    );
  };
}

export function makeSubmissionTable(elem, props) {
  render(<SubmissionTable {...props} />, elem);
}
