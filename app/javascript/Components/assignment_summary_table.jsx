import React from "react";
import {getMarkingStates, selectFilter} from "./Helpers/table_helpers";

import DownloadTestResultsModal from "./Modals/download_test_results_modal";
import LtiGradeModal from "./Modals/send_lti_grades_modal";
import {createColumnHelper} from "@tanstack/react-table";
import Table from "./table/table";

export class AssignmentSummaryTable extends React.Component {
  constructor(props) {
    super(props);
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
      columnFilters: [{id: "inactive", value: false}],
      inactiveGroupsCount: 0,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  getColumns = () => {
    const columnHelper = createColumnHelper();

    const fixedColumns = [
      columnHelper.accessor("inactive", {
        id: "inactive",
      }),
      columnHelper.accessor("group_name", {
        id: "group_name",
        header: () => I18n.t("activerecord.models.group.one"),
        size: 100,
        enableResizing: true,
        cell: props => {
          if (props.row.original.result_id) {
            const path = Routes.edit_course_result_path(
              this.props.course_id,
              props.row.original.result_id
            );
            return (
              <a href={path}>
                {props.getValue()}
                {this.memberDisplay(props.getValue(), props.row.original.members)}
              </a>
            );
          } else {
            return (
              <span>
                {props.row.original.group_name}
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
            return row.original.graders.some(grader => grader.includes(filterValue));
          } else {
            return true;
          }
        },
      }),
      columnHelper.accessor("marking_state", {
        header: () => I18n.t("activerecord.attributes.result.marking_state"),
        accessorKey: "marking_state",
        size: 100,
        enableResizing: true,
        cell: props => props.getValue(),
        filterFn: "equalsString",
        meta: {
          filterVariant: "select",
        },
        filterAllOptionText:
          I18n.t("all") +
          (this.state.markingStateFilter === "all"
            ? ` (${Object.values(this.state.marking_states).reduce((a, b) => a + b)})`
            : ""),
        filterOptions: [
          {
            value: "before_due_date",
            text:
              I18n.t("submissions.state.before_due_date") +
              (["before_due_date", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["before_due_date"]})`
                : ""),
          },
          {
            value: "not_collected",
            text:
              I18n.t("submissions.state.not_collected") +
              (["not_collected", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["not_collected"]})`
                : ""),
          },
          {
            value: "incomplete",
            text:
              I18n.t("submissions.state.in_progress") +
              (["incomplete", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["incomplete"]})`
                : ""),
          },
          {
            value: "complete",
            text:
              I18n.t("submissions.state.complete") +
              (["complete", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["complete"]})`
                : ""),
          },
          {
            value: "released",
            text:
              I18n.t("submissions.state.released") +
              (["released", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["released"]})`
                : ""),
          },
          {
            value: "remark",
            text:
              I18n.t("submissions.state.remark_requested") +
              (["remark", "all"].includes(this.state.markingStateFilter)
                ? ` (${this.state.marking_states["remark"]})`
                : ""),
          },
        ],
        Filter: selectFilter,
      }),
      columnHelper.accessor("tags", {
        header: () => I18n.t("activerecord.models.tag.other"),
        size: 90,
        enableResizing: true,
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
      columnHelper.accessor("final_grade", {
        header: () => I18n.t("results.total_mark"),
        size: 100,
        enableResizing: true,
        cell: props => {
          if (props.row.original.final_grade || props.row.original.final_grade === 0) {
            const max_mark = Math.round(props.row.original.max_mark * 100) / 100;
            return props.row.original.final_grade + " / " + max_mark;
          } else {
            return "";
          }
        },
        meta: {className: "number"},
        enableColumnFilter: false,
        sortDescFirst: true,
      }),
    ];

    const criteriaColumns = this.state.criteriaColumns.map(col =>
      columnHelper.accessor(col.accessor, {
        id: col.id,
        header: () => col.Header,
        size: col.size || 100,
        meta: {
          className: col.className,
          headerClassName: col.headerClassName,
        },
        enableColumnFilter: col.enableColumnFilter,
        sortDescFirst: col.sortDescFirst,
      })
    );

    const bonusColumn = columnHelper.accessor("total_extra_marks", {
      header: () => I18n.t("activerecord.models.extra_mark.other"),
      size: 100,
      enableResizing: true,
      meta: {className: "number"},
      enableColumnFilter: false,
      sortDescFirst: true,
    });

    return [...fixedColumns, ...criteriaColumns, bonusColumn];
  };

  toggleShowInactiveGroups = showInactiveGroups => {
    let columnFilters = this.state.columnFilters.filter(group => group.id !== "inactive");

    if (!showInactiveGroups) {
      columnFilters.push({id: "inactive", value: false});
    }

    this.setState({columnFilters});
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
    return fetch(
      Routes.summary_course_assignment_path(this.props.course_id, this.props.assignment_id),
      {
        headers: {
          Accept: "application/json",
        },
      }
    )
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        res.criteriaColumns.forEach(col => {
          col.enableColumnFilter = false;
          col.sortDescFirst = true;
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

        const processedData = this.processData(res.data);
        const markingStates = getMarkingStates(processedData);
        this.setState({
          data: processedData,
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

  processData(data) {
    data.forEach(row => {
      switch (row.marking_state) {
        case "not_collected":
          row.marking_state = I18n.t("submissions.state.not_collected");
          break;
        case "incomplete":
          row.marking_state = I18n.t("submissions.state.in_progress");
          break;
        case "complete":
          row.marking_state = I18n.t("submissions.state.complete");
          break;
        case "released":
          row.marking_state = I18n.t("submissions.state.released");
          break;
        case "remark":
          row.marking_state = I18n.t("submissions.state.remark_requested");
          break;
        case "before_due_date":
          row.marking_state = I18n.t("submissions.state.before_due_date");
          break;
        default:
          // should not get here
          row.marking_state = row.original.marking_state;
      }
    });
    return data;
  }

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

  onDownloadTestsModal = () => {
    this.setState({showDownloadTestsModal: true});
  };

  onLtiGradeModal = () => {
    this.setState({showLtiGradeModal: true});
  };

  render() {
    const {data} = this.state;
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
          columns={this.getColumns()}
          initialState={{
            sorting: [{id: "group_name"}],
          }}
          columnFilters={this.state.columnFilters}
          getRowCanExpand={() => true}
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

const renderSubComponent = ({row}) => {
  return (
    <div>
      <h4>{I18n.t("activerecord.models.ta", {count: row.original.graders.length})}</h4>
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
