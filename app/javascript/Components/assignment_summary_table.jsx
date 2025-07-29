import React from "react";
import {markingStateColumn, getMarkingStates} from "./Helpers/table_helpers";

import DownloadTestResultsModal from "./Modals/download_test_results_modal";
import LtiGradeModal from "./Modals/send_lti_grades_modal";
import {createColumnHelper} from "@tanstack/react-table";
import Table from "./table/table";

export class AssignmentSummaryTable extends React.Component {
  constructor() {
    super();
    const markingStates = getMarkingStates([]);
    this.state = {
      data: [],
      criteriaColumns: [],
      loading: true,
      num_assigned: 0,
      num_marked: 0,
      enable_test: false,
      marking_states: markingStates,
      markingStateFilter: "all",
      showDownloadTestsModal: false,
      showLtiGradeModal: false,
      lti_deployments: [],
      filtered: [],
      inactiveGroupsCount: 0,
    };
    this.columnHelper = createColumnHelper();
  }

  componentDidMount() {
    this.fetchData();
  }

  toggleShowInactiveGroups = showInactiveGroups => {
    let filtered = this.state.filtered.filter(group => group.id !== "inactive");

    if (!showInactiveGroups) {
      filtered.push({id: "inactive", value: false});
    }

    this.setState({filtered});
  };

  memberDisplay = (group_name, members) => {
    if (members.length !== 0 && !(members.length === 1 && members[0][0] === group_name)) {
      return (
        " (" +
        members
          .map(member => {
            return member[0];
          })
          .join(", ") +
        ")"
      );
    }
  };

  fetchData = () => {
    fetch(Routes.summary_course_assignment_path(this.props.course_id, this.props.assignment_id), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        res.criteriaColumns.forEach(col => {
          col["filterable"] = false;
          col["defaultSortDesc"] = true;
        });

        let inactive_groups_count = 0;
        res.data.forEach(group => {
          if (group.members.length && group.members.every(member => member[3])) {
            group.inactive = true;
            inactive_groups_count++;
          } else {
            group.inactive = false;
          }
        });

        this.toggleShowInactiveGroups(false);

        const markingStates = getMarkingStates(res.data);
        this.setState({
          data: res.data,
          criteriaColumns: res.criteriaColumns,
          num_assigned: res.numAssigned,
          num_marked: res.numMarked,
          enable_test: res.enableTest,
          loading: false,
          marking_states: markingStates,
          lti_deployments: res.ltiDeployments,
          inactiveGroupsCount: inactive_groups_count,
        });
      });
  };

  onFilteredChange = (filtered, column) => {
    const summaryTable = this.wrappedInstance;
    if (column.id != "marking_state") {
      const markingStates = getMarkingStates(summaryTable.state.sortedData);
      this.setState({marking_states: markingStates});
    } else {
      const markingStateFilter = filtered.find(filter => filter.id == "marking_state").value;
      this.setState({markingStateFilter: markingStateFilter});
    }
  };

  fixedColumns = () => {
    return [
      this.columnHelper.accessor("inactive", {
        id: "inactive",
      }),
      this.columnHelper.accessor("group_name", {
        id: "group_name",
        header: () => I18n.t("activerecord.models.group.one"),
        cell: props => {
          if (props.row.original.result_id) {
            const path = Routes.edit_course_result_path(
              this.props.course_id,
              props.row.original.result_id
            );
            return (
              <a href={path}>
                {props.getValue()}
                {this.memberDisplay(props.row.original.group_name, props.row.original.members)}
              </a>
            );
          } else {
            return (
              <span>
                {props.getValue()}
                {this.memberDisplay(props.row.original.group_name, props.row.original.members)}
              </span>
            );
          }
        },
        filterFn: (row, columnId, filterValue) => {
          if (filterValue) {
            // Check group name
            if (row.original.group_name.includes(filterValue)) {
              return true;
            }

            // Check member names
            const member_matches = row.original.members.some(member =>
              member.some(name => name.includes(filterValue))
            );

            if (member_matches) {
              return true;
            }

            // Check grader user names
            return row.original.graders.some(grader => grader.includes(filter.value));
          } else {
            return true;
          }
        },
      }),
      markingStateColumn(this.state.marking_states, this.state.markingStateFilter),
      this.columnHelper.accessor("tags", {
        header: () => I18n.t("activerecord.models.tag.other"),
        cell: props => (
          <ul className="tag-list">
            {props.row.original.tags.map(tag => (
              <li key={`${props.row.original._id}-${tag}`} className="tag-element">
                {tag}
              </li>
            ))}
          </ul>
        ),
        minWidth: 80,
        enableSorting: false,
        filterFn: (row, columnId, filterValue) => {
          if (filterValue) {
            // Check tag names
            return row.original.tags.some(tag => tag.includes(filterValue));
          } else {
            return true;
          }
        },
      }),
      this.columnHelper.accessor("final_grade", {
        header: () => I18n.t("results.total_mark"),
        cell: props => {
          if (props.getValue() || props.getValue() === 0) {
            const max_mark = Math.round(props.row.original.max_mark * 100) / 100;
            return props.getValue() + " / " + max_mark;
          } else {
            return "";
          }
        },
        meta: {className: "number"},
        enableColumnFilter: false,
        sortDescFirst: true,
      }),
    ];
  };

  bonusColumn = this.columnHelper.accessor("total_extra_marks", {
    header: () => I18n.t("activerecord.models.extra_mark.other"),
    cell: props => props.getValue(),
    meta: {className: "number"},
    enableColumnFilter: false,
    sortDescFirst: true,
  });

  onDownloadTestsModal = () => {
    this.setState({showDownloadTestsModal: true});
  };

  onLtiGradeModal = () => {
    this.setState({showLtiGradeModal: true});
  };

  render() {
    const {data, criteriaColumns} = this.state;
    let ltiButton;
    if (this.state.lti_deployments.length > 0) {
      ltiButton = (
        <button type="submit" name="sync_grades" onClick={this.onLtiGradeModal}>
          {I18n.t("lti.sync_grades_lms")}
        </button>
      );
    }

    let displayInactiveGroupsTooltip = "";

    if (this.state.inactiveGroupsCount !== null) {
      displayInactiveGroupsTooltip = `${I18n.t("activerecord.attributes.grouping.inactive_groups", {
        count: this.state.inactiveGroupsCount,
      })}`;
    }

    const renderSubComponent = row => {
      return (
        <div>
          <h4>{I18n.t("activerecord.models.ta", {count: 2})}</h4>
          <ul>
            {row.original.graders.map(grader => {
              return (
                <li key={grader[0]}>
                  ({grader[0]}) {grader[1]} {grader[2]}
                </li>
              );
            })}
          </ul>
        </div>
      );
    };

    return (
      <div>
        <div style={{display: "inline-block"}}>
          <div className="progress">
            <meter
              value={this.state.num_marked}
              min={0}
              max={this.state.num_assigned}
              low={this.state.num_assigned * 0.35}
              high={this.state.num_assigned * 0.75}
              optimum={this.state.num_assigned}
            >
              {this.state.num_marked}/{this.state.num_assigned}
            </meter>
            {this.state.num_marked}/{this.state.num_assigned}&nbsp;
            {I18n.t("submissions.state.complete")}
          </div>
        </div>
        <div className="rt-action-box">
          <input
            id="show_inactive_groups"
            name="show_inactive_groups"
            type="checkbox"
            onChange={e => this.toggleShowInactiveGroups(e.target.checked)}
            className={"hide-user-checkbox"}
            data-testid={"show_inactive_groups"}
          />
          <label
            title={displayInactiveGroupsTooltip}
            htmlFor="show_inactive_groups"
            data-testid={"show_inactive_groups_tooltip"}
          >
            {I18n.t("submissions.groups.display_inactive")}
          </label>
          {this.props.is_instructor && (
            <>
              <form
                action={Routes.summary_course_assignment_path({
                  course_id: this.props.course_id,
                  id: this.props.assignment_id,
                  format: "csv",
                  _options: true,
                })}
                method="get"
              >
                <button type="submit" name="download">
                  {I18n.t("download")}
                </button>
              </form>
              {this.state.enable_test && (
                <button type="submit" name="download_tests" onClick={this.onDownloadTestsModal}>
                  {I18n.t("download_the", {
                    item: I18n.t("activerecord.models.test_result.other"),
                  })}
                </button>
              )}
              {ltiButton}
            </>
          )}
        </div>
        <Table
          data={data}
          columns={this.fixedColumns().concat(criteriaColumns, [this.bonusColumn])}
          state={{
            columnFilters: this.state.filtered,
            columnVisibility: {
              inactive: false,
            },
          }}
          initialState={{
            sorting: [{id: "group_name"}],
          }}
          onColumnFiltersChange={this.onFilteredChange}
          renderSubComponent={renderSubComponent}
          loading={this.state.loading}
        />
        <DownloadTestResultsModal
          course_id={this.props.course_id}
          assignment_id={this.props.assignment_id}
          isOpen={this.state.showDownloadTestsModal}
          onRequestClose={() => this.setState({showDownloadTestsModal: false})}
          onSubmit={() => {}}
        />
        <LtiGradeModal
          isOpen={this.state.showLtiGradeModal}
          onRequestClose={() => this.setState({showLtiGradeModal: false})}
          lti_deployments={this.state.lti_deployments}
          assignment_id={this.props.assignment_id}
          course_id={this.props.course_id}
        />
      </div>
    );
  }
}
