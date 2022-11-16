import React from "react";
import {render} from "react-dom";

import {CheckboxTable, withSelection} from "./markus_with_selection_hoc";
import {
  dateSort,
  markingStateColumn,
  selectFilter,
  getMarkingStates,
} from "./Helpers/table_helpers";
import CollectSubmissionsModal from "./Modals/collect_submissions_modal";
import ReleaseUrlsModal from "./Modals/release_urls_modal";

class RawSubmissionTable extends React.Component {
  constructor() {
    super();
    const markingStates = getMarkingStates([]);
    this.state = {
      groupings: [],
      sections: {},
      loading: true,
      showCollectSubmissionsModal: false,
      showReleaseUrlsModal: false,
      marking_states: markingStates,
      markingStateFilter: "all",
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      dataType: "json",
    }).then(res => {
      this.props.resetSelection();
      const markingStates = getMarkingStates(res.groupings);
      this.setState({
        groupings: res.groupings,
        sections: res.sections,
        loading: false,
        marking_states: markingStates,
      });
    });
  };

  onFilteredChange = (filtered, column) => {
    const summaryTable = this.checkboxTable.getWrappedInstance();
    if (column.id != "marking_state") {
      const markingStates = getMarkingStates(summaryTable.state.sortedData);
      this.setState({marking_states: markingStates});
    } else {
      const markingStateFilter = filtered.find(filter => filter.id == "marking_state").value;
      this.setState({markingStateFilter: markingStateFilter});
    }
  };

  groupNameWithMembers = row => {
    let members = "";
    if (
      !row.original.members ||
      (row.original.members.length === 1 && row.value === row.original.members[0])
    ) {
      members = "";
    } else {
      members = ` (${row.original.members.join(", ")})`;
    }
    return row.value + members;
  };

  groupNameFilter = (filter, row) => {
    if (filter.value) {
      // Check group name
      if (row._original.group_name.includes(filter.value)) {
        return true;
      }
      // Check member names
      return (
        row._original.members && row._original.members.some(name => name.includes(filter.value))
      );
    } else {
      return true;
    }
  };

  columns = () => [
    {
      show: false,
      accessor: "_id",
      id: "_id",
    },
    {
      Header: I18n.t("activerecord.models.group.one"),
      accessor: "group_name",
      id: "group_name",
      Cell: row => {
        const group_name = this.groupNameWithMembers(row);
        if (row.original.result_id) {
          const result_url = Routes.edit_course_result_path(
            this.props.course_id,
            row.original.result_id
          );
          return <a href={result_url}>{group_name}</a>;
        } else {
          return group_name;
        }
      },
      minWidth: 170,
      filterMethod: this.groupNameFilter,
    },
    {
      Header: I18n.t("submissions.repo_browser.repository"),
      filterable: false,
      sortable: false,
      Cell: row => {
        return (
          <a
            href={Routes.repo_browser_course_assignment_submissions_path(
              this.props.course_id,
              this.props.assignment_id,
              {
                grouping_id: row.original._id,
              }
            )}
          >
            {row.original.group_name}
          </a>
        );
      },
      minWidth: 80,
    },
    {
      Header: I18n.t("activerecord.models.section", {count: 1}),
      accessor: "section",
      id: "section",
      show: this.props.show_sections,
      minWidth: 70,
      filterMethod: (filter, row) => {
        if (filter.value === "all") {
          return true;
        } else {
          return filter.value === row[filter.id];
        }
      },
      Filter: selectFilter,
      filterOptions: Object.entries(this.state.sections).map(kv => ({
        value: kv[1],
        text: kv[1],
      })),
    },
    {
      show: this.props.is_timed,
      Header: I18n.t("activerecord.attributes.assignment.start_time"),
      accessor: "start_time",
      filterable: false,
      sortMethod: dateSort,
    },
    {
      Header: I18n.t("submissions.commit_date"),
      accessor: "submission_time",
      filterable: false,
      sortMethod: dateSort,
    },
    {
      Header: I18n.t("submissions.grace_credits_used"),
      accessor: "grace_credits_used",
      show: this.props.show_grace_tokens,
      minWidth: 100,
      style: {textAlign: "right"},
    },
    markingStateColumn(this.state.marking_states, this.state.markingStateFilter, {minWidth: 70}),
    {
      Header: I18n.t("activerecord.attributes.result.total_mark"),
      accessor: "final_grade",
      Cell: row => {
        const value =
          row.original.final_grade === undefined
            ? "-"
            : Math.round(row.original.final_grade * 100) / 100;
        const max_mark = Math.round(row.original.max_mark * 100) / 100;
        return value + " / " + max_mark;
      },
      className: "number",
      minWidth: 80,
      filterable: false,
      defaultSortDesc: true,
    },
    {
      Header: I18n.t("activerecord.models.tag.other"),
      accessor: "tags",
      Cell: row => (
        <ul className="tag-list">
          {row.original.tags.map(tag => (
            <li key={`${row.original._id}-${tag}`} className="tag-element">
              {tag}
            </li>
          ))}
        </ul>
      ),
      minWidth: 80,
      sortable: false,
    },
  ];

  // Custom getTrProps function to highlight submissions that have been collected.
  getTrProps = (state, ri, ci, instance) => {
    if (
      ri.original.marking_state === undefined ||
      ri.original.marking_state === "not_collected" ||
      ri.original.marking_state === "before_due_date"
    ) {
      return {ri};
    } else {
      return {
        ri,
        style: {
          background: document.documentElement.style.getPropertyValue("--light_success"),
        },
      };
    }
  };

  // Submission table actions
  collectSubmissions = (override, collect_current, apply_late_penalty) => {
    this.setState({showCollectSubmissionsModal: false});
    $.post({
      url: Routes.collect_submissions_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        groupings: this.props.selection,
        override: override,
        collect_current: collect_current,
        apply_late_penalty: apply_late_penalty,
      },
    });
  };

  uncollectAllSubmissions = () => {
    if (!window.confirm(I18n.t("submissions.collect.undo_results_loss_warning"))) {
      return;
    }

    $.get({
      url: Routes.uncollect_all_submissions_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {groupings: this.props.selection},
    });
  };

  setMarkingStates = marking_state => {
    $.post({
      url: Routes.set_result_marking_state_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        groupings: this.props.selection,
        marking_state: marking_state,
      },
    }).then(this.fetchData);
  };

  prepareGroupingFiles = () => {
    if (window.confirm(I18n.t("submissions.marking_incomplete_warning"))) {
      $.post({
        url: Routes.zip_groupings_files_course_assignment_submissions_url(
          this.props.course_id,
          this.props.assignment_id
        ),
        data: {
          groupings: this.props.selection,
        },
      });
    }
  };

  runTests = () => {
    $.post({
      url: Routes.run_tests_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {groupings: this.props.selection},
    });
  };

  toggleRelease = released => {
    this.setState({loading: true}, () => {
      $.post({
        url: Routes.update_submissions_course_assignment_submissions_path(
          this.props.course_id,
          this.props.assignment_id
        ),
        data: {
          release_results: released,
          groupings: this.props.selection,
        },
      })
        .then(this.fetchData)
        .catch(this.fetchData);
    });
  };

  refreshViewTokens = (updated_tokens, after_function) => {
    this.setState(prevState => {
      prevState.groupings.forEach(row => {
        if (updated_tokens[row.result_id]) {
          row["result_view_token"] = updated_tokens[row.result_id];
        }
      });
      return prevState;
    }, after_function);
  };

  refreshViewTokenExpiry = (updated_tokens, after_function) => {
    this.setState(prevState => {
      prevState.groupings.forEach(row => {
        if (updated_tokens[row.result_id] !== undefined) {
          row["result_view_token_expiry"] = updated_tokens[row.result_id];
        }
      });
      return prevState;
    }, after_function);
  };

  render() {
    const {loading} = this.state;

    return (
      <div>
        <SubmissionsActionBox
          ref={r => (this.actionBox = r)}
          disabled={this.props.selection.length === 0}
          can_collect={this.props.can_collect}
          assignment_id={this.props.assignment_id}
          can_run_tests={this.props.can_run_tests}
          collectSubmissions={() => {
            this.setState({showCollectSubmissionsModal: true});
          }}
          downloadGroupingFiles={this.prepareGroupingFiles}
          showReleaseUrls={() => this.setState({showReleaseUrlsModal: true})}
          selection={this.props.selection}
          runTests={this.runTests}
          releaseMarks={() => this.toggleRelease(true)}
          unreleaseMarks={() => this.toggleRelease(false)}
          completeResults={() => this.setMarkingStates("complete")}
          incompleteResults={() => this.setMarkingStates("incomplete")}
          authenticity_token={this.props.authenticity_token}
          release_with_urls={this.props.release_with_urls}
        />
        <CheckboxTable
          ref={r => (this.checkboxTable = r)}
          data={this.state.groupings}
          columns={this.columns()}
          defaultSorted={[
            {
              id: "group_name",
            },
          ]}
          filterable
          defaultFiltered={this.props.defaultFiltered}
          onFilteredChange={this.onFilteredChange}
          loading={loading}
          getTrProps={this.getTrProps}
          {...this.props.getCheckboxProps()}
        />
        <CollectSubmissionsModal
          isOpen={this.state.showCollectSubmissionsModal}
          isScannedExam={this.props.is_scanned_exam}
          onRequestClose={() => {
            this.setState({showCollectSubmissionsModal: false});
          }}
          onSubmit={this.collectSubmissions}
        />
        <ReleaseUrlsModal
          isOpen={this.state.showReleaseUrlsModal}
          data={this.state.groupings.filter(
            g => this.props.selection.includes(g._id) && !!g.result_view_token
          )}
          groupNameWithMembers={this.groupNameWithMembers}
          groupNameFilter={this.groupNameFilter}
          course_id={this.props.course_id}
          assignment_id={this.props.assignment_id}
          refreshViewTokens={this.refreshViewTokens}
          refreshViewTokenExpiry={this.refreshViewTokenExpiry}
          onRequestClose={() => {
            this.setState({showReleaseUrlsModal: false});
          }}
        />
      </div>
    );
  }
}

let SubmissionTable = withSelection(RawSubmissionTable);
SubmissionTable.defaultProps = {
  can_collect: false,
  is_timed: false,
  can_run_tests: false,
};

class SubmissionsActionBox extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      button_disabled: false,
    };
  }

  render = () => {
    let completeButton,
      incompleteButton,
      collectButton,
      runTestsButton,
      releaseMarksButton,
      unreleaseMarksButton,
      showReleaseUrlsButton;

    completeButton = (
      <button onClick={this.props.completeResults} disabled={this.props.disabled}>
        {I18n.t("results.set_to_complete")}
      </button>
    );

    incompleteButton = (
      <button onClick={this.props.incompleteResults} disabled={this.props.disabled}>
        {I18n.t("results.set_to_incomplete")}
      </button>
    );
    if (this.props.can_collect) {
      collectButton = (
        <button onClick={this.props.collectSubmissions} disabled={this.props.disabled}>
          {I18n.t("submissions.collect.submit")}
        </button>
      );

      releaseMarksButton = (
        <button disabled={this.props.disabled} onClick={this.props.releaseMarks}>
          {I18n.t("submissions.release_marks")}
        </button>
      );
      unreleaseMarksButton = (
        <button disabled={this.props.disabled} onClick={this.props.unreleaseMarks}>
          {I18n.t("submissions.unrelease_marks")}
        </button>
      );
      if (this.props.release_with_urls) {
        showReleaseUrlsButton = (
          <button onClick={this.props.showReleaseUrls} disabled={this.props.disabled}>
            {I18n.t("submissions.show_release_tokens")}
          </button>
        );
      }
    }
    if (this.props.can_run_tests) {
      runTestsButton = (
        <button onClick={this.props.runTests} disabled={this.props.disabled}>
          {I18n.t("submissions.run_tests")}
        </button>
      );
    }

    let downloadGroupingFilesButton = (
      <button onClick={this.props.downloadGroupingFiles} disabled={this.props.disabled}>
        {I18n.t("download_the", {
          item: I18n.t("activerecord.models.submission.other"),
        })}
      </button>
    );

    return (
      <div className="rt-action-box">
        {completeButton}
        {incompleteButton}
        {collectButton}
        {downloadGroupingFilesButton}
        {runTestsButton}
        {releaseMarksButton}
        {unreleaseMarksButton}
        {showReleaseUrlsButton}
      </div>
    );
  };
}

export function makeSubmissionTable(elem, props) {
  return render(<SubmissionTable {...props} />, elem);
}
