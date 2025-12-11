import React from "react";
import ReactTable from "react-table";
import {selectFilter} from "./Helpers/table_helpers";
import {TestGroupFeedbackFileTable} from "./test_group_feedback_file_table";

export class TestGroupResultTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show_output: this.showOutput(props.data),
      expanded: this.computeExpanded(props.data),
      filtered: [],
      filteredData: props.data,
    };
  }

  componentDidUpdate(prevProps) {
    if (prevProps.data !== this.props.data) {
      this.setState({filteredData: this.props.data, filtered: []});
    }
  }

  computeExpanded = data => {
    let expanded = {};
    let i = 0;
    let groups = new Set();
    data.forEach(row => {
      if (!groups.has(row["test_groups.id"])) {
        expanded[i] = {};
        i++;
        groups.add(row["test_groups.id"]);
      }
    });
    return expanded;
  };

  onExpandedChange = newExpanded => {
    this.setState({expanded: newExpanded});
  };

  showOutput = data => {
    if (data) {
      return data.some(row => "test_results.output" in row);
    } else {
      return false;
    }
  };

  columns = () => [
    {
      id: "test_group_id",
      Header: "",
      accessor: row => row["test_groups.id"],
      maxWidth: 30,
    },
    {
      id: "test_group_name",
      Header: "",
      accessor: row => row["test_groups.name"],
      maxWidth: 30,
      show: false,
    },
    {
      id: "name",
      Header: I18n.t("activerecord.attributes.test_result.name"),
      accessor: row => row["test_results.name"],
      aggregate: (values, rows) => {
        if (rows.length === 0) {
          return "";
        } else {
          return rows[0]["test_group_name"];
        }
      },
      minWidth: 200,
    },
    {
      id: "test_status",
      Header: I18n.t("activerecord.attributes.test_result.status"),
      accessor: "test_results_status",
      width: 80,
      aggregate: (vals, rows) => {
        const hasTimeout = rows.some(
          row => row._original["test_group_results.error_type"] === "timeout"
        );
        return hasTimeout ? "timeout" : "";
      },
      Aggregated: row => {
        return row.value === "timeout"
          ? I18n.t("activerecord.attributes.test_group_result.timeout")
          : "";
      },
      filterable: true,
      Filter: selectFilter,
      filterOptions: ["pass", "partial", "fail", "error", "error_all"].map(status => ({
        value: status,
        text: status,
      })),
      // Disable the default filter method because this is a controlled component
      filterMethod: () => true,
    },
    {
      id: "marks_earned",
      Header: I18n.t("activerecord.attributes.test_result.marks_earned"),
      accessor: row => row["test_results.marks_earned"],
      Cell: row => {
        const marksEarned = row.original["test_results.marks_earned"];
        const marksTotal = row.original["test_results.marks_total"];
        if (marksEarned !== null && marksTotal !== null) {
          return `${marksEarned} / ${marksTotal}`;
        } else {
          return "";
        }
      },
      width: 80,
      className: "number",
      aggregate: (vals, rows) =>
        rows.reduce(
          (acc, row) => [
            acc[0] + (row._original["test_results.marks_earned"] || 0),
            acc[1] + (row._original["test_results.marks_total"] || 0),
          ],
          [0, 0]
        ),
      Aggregated: row => {
        const timeout_reached = row.value[0] === 0 && row.value[1] === 0;
        const ret_val = timeout_reached
          ? I18n.t("activerecord.attributes.test_group_result.no_test_results")
          : `${row.value[0]} / ${row.value[1]}`;
        return ret_val;
      },
    },
  ];

  filterByStatus = filtered => {
    let status;
    for (const filter of filtered) {
      if (filter.id === "test_status") {
        status = filter.value;
      }
    }

    let filteredData;
    if (!!status && status !== "all") {
      filteredData = this.props.data.filter(row => row.test_results_status === status);
    } else {
      filteredData = this.props.data;
    }

    this.setState({
      filtered,
      filteredData,
      expanded: this.computeExpanded(filteredData),
    });
  };

  render() {
    const seen = new Set();
    const extraInfo = this.props.data
      .reduce((acc, test_data) => {
        const id = test_data["test_groups.id"];
        const name = (test_data["test_groups.name"] || "").trim();
        const info = (test_data["test_group_results.extra_info"] || "").trim();

        if (!seen.has(id) && info) {
          seen.add(id);
          acc.push(`[${name}]`, info);
        }

        return acc;
      }, [])
      .join("\n");
    let extraInfoDisplay;
    if (extraInfo) {
      extraInfoDisplay = (
        <div>
          <h4>{I18n.t("activerecord.attributes.test_group_result.extra_info")}</h4>
          <pre>{extraInfo}</pre>
        </div>
      );
    } else {
      extraInfoDisplay = "";
    }
    const feedbackFiles = [];
    this.props.data.forEach(data => {
      data.feedback_files.forEach(feedbackFile => {
        if (!feedbackFiles.some(f => f.id === feedbackFile.id)) {
          feedbackFiles.push(feedbackFile);
        }
      });
    });
    let feedbackFileDisplay;
    if (feedbackFiles.length) {
      feedbackFileDisplay = (
        <TestGroupFeedbackFileTable data={feedbackFiles} course_id={this.props.course_id} />
      );
    } else {
      feedbackFileDisplay = "";
    }

    return (
      <div>
        <ReactTable
          className={this.state.loading ? "auto-overflow" : "auto-overflow display-block"}
          data={this.state.filteredData}
          columns={this.columns()}
          pivotBy={["test_group_id"]}
          getTdProps={(state, rowInfo) => {
            if (rowInfo) {
              let className = `-wrap test-result-${rowInfo.row["test_status"]}`;
              if (
                !rowInfo.aggregated &&
                (!this.state.show_output || !rowInfo.original["test_results.output"])
              ) {
                className += " hide-rt-expander";
              }
              return {className: className};
            } else {
              return {};
            }
          }}
          PivotValueComponent={() => ""}
          expanded={this.state.expanded}
          filtered={this.state.filtered}
          onFilteredChange={this.filterByStatus}
          onExpandedChange={this.onExpandedChange}
          collapseOnDataChange={false}
          collapseOnSortingChange={false}
          SubComponent={row => (
            <pre className={`test-results-output test-result-${row.row["test_status"]}`}>
              {row.original["test_results.output"]}
            </pre>
          )}
          style={{maxHeight: "initial"}}
        />
        {extraInfoDisplay}
        {feedbackFileDisplay}
      </div>
    );
  }
}
