import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import mime from "mime/lite";
import {dateSort, selectFilter} from "./Helpers/table_helpers";
import {FileViewer} from "./Result/file_viewer";
import consumer from "../channels/consumer";
import {renderFlashMessages} from "../common/flash";

export class TestRunTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: [],
      loading: true,
      expanded: {},
    };
    this.testRuns = React.createRef();
  }

  componentDidMount() {
    this.fetchData();
    this.create_test_runs_channel_subscription();
  }

  componentDidUpdate(prevProps) {
    if (
      prevProps.result_id !== this.props.result_id ||
      prevProps.instructor_run !== this.props.instructor_run ||
      prevProps.instructor_view !== this.props.instructor_view
    ) {
      this.setState({loading: true}, this.fetchData);
    }
  }

  fetchData = () => {
    let fetchDetails = {
      headers: {
        Accept: "application/json",
      },
    };
    let url;
    if (this.props.instructor_run) {
      if (this.props.instructor_view) {
        url = Routes.get_test_runs_instructors_course_result_path(
          this.props.course_id,
          this.props.result_id
        );
      } else {
        url = Routes.get_test_runs_instructors_released_course_result_path(
          this.props.course_id,
          this.props.result_id
        );
      }
    } else {
      url = Routes.get_test_runs_students_course_assignment_automated_tests_path(
        this.props.course_id,
        this.props.assignment_id
      );
    }
    fetch(url, fetchDetails)
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(data => {
        this.setState({
          data: data,
          loading: false,
          expanded: data.length > 0 ? {0: true} : {},
        });
      });
  };

  onExpandedChange = newExpanded => this.setState({expanded: newExpanded});

  create_test_runs_channel_subscription = () => {
    consumer.subscriptions.create(
      {
        channel: "TestRunsChannel",
        course_id: this.props.course_id,
        assignment_id: this.props.assignment_id,
        grouping_id: this.props.grouping_id,
        submission_id: this.props.submission_id,
      },
      {
        connected: () => {},
        disconnected: () => {},
        received: data => {
          // Called when there's incoming data on the websocket for this channel
          if (data["status"] !== null) {
            let message_data = generateMessage(data);
            renderFlashMessages(message_data);
          }
          if (data["status"] === "completed") {
            // Note: this gets called after AutotestRunJob completes (when a new
            // TestRun is created), and after an AutotestResultsJob completed
            // (when test results are available).
            this.fetchData();
          }
        },
      }
    );
  };

  render() {
    let height;
    if (this.props.instructor_view) {
      // 3.5em is the vertical space for the action bar (and run tests button)
      height = "calc(599px - 3.5em)";
    } else {
      height = "599px";
    }

    return (
      <div>
        <ReactTable
          ref={this.testRuns}
          data={this.state.data}
          key={this.state.data.length ? this.state.data[0]["test_runs.id"] : "empty-table"}
          columns={[
            {
              id: "created_at",
              accessor: row => row["test_runs.created_at"],
              sortMethod: dateSort,
              minWidth: 300,
            },
            {
              id: "user_name",
              accessor: row => row["users.user_name"],
              Cell: ({value}) => I18n.t("activerecord.attributes.test_run.user") + " " + value,
              show: !this.props.instructor_run || this.props.instructor_view,
              width: 120,
            },
            {
              id: "status",
              accessor: row =>
                I18n.t(`automated_tests.test_runs_statuses.${row["test_runs.status"]}`),
              width: 120,
            },
          ]}
          SubComponent={row =>
            row.original["test_runs.problems"] ? (
              <pre>{row.original["test_runs.problems"]}</pre>
            ) : (
              <TestGroupResultTable
                key={row.original.id_}
                data={row.original["test_results"]}
                course_id={this.props.course_id}
              />
            )
          }
          noDataText={I18n.t("automated_tests.no_results")}
          getTheadProps={() => {
            return {
              style: {display: "none"},
            };
          }}
          defaultSorted={[{id: "created_at", desc: true}]}
          expanded={this.state.expanded}
          onExpandedChange={this.onExpandedChange}
          loading={this.state.loading}
          style={{maxHeight: height}}
        />
      </div>
    );
  }
}

class TestGroupResultTable extends React.Component {
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

class TestGroupFeedbackFileTable extends React.Component {
  render() {
    const columns = [
      {
        Header: I18n.t("activerecord.attributes.submission.feedback_files"),
        accessor: "filename",
      },
    ];

    return (
      <ReactTable
        className={"auto-overflow test-result-feedback-files"}
        data={this.props.data}
        columns={columns}
        SubComponent={row => (
          <FileViewer
            selectedFile={row.original.filename}
            selectedFileURL={Routes.course_feedback_file_path(
              this.props.course_id,
              row.original.id
            )}
            mime_type={mime.getType(row["filename"])}
            selectedFileType={row.original.type}
            rmd_convert_enabled={this.props.rmd_convert_enabled}
          />
        )}
      />
    );
  }
}

export function makeTestRunTable(elem, props) {
  const root = createRoot(elem);
  root.render(<TestRunTable {...props} />);
}

function generateMessage(status_data) {
  let message_data = {};
  switch (status_data["status"]) {
    case "failed":
      if (!status_data["exception"] || !status_data["exception"]["message"]) {
        message_data["error"] = I18n.t("job.status.failed.no_message");
      } else {
        message_data["error"] = I18n.t("job.status.failed.message", {
          error: status_data["exception"]["message"],
        });
      }
      break;
    case "completed":
      if (status_data["job_class"] === "AutotestRunJob") {
        message_data["success"] = I18n.t("automated_tests.autotest_run_job.status.completed");
      } else {
        message_data["success"] = I18n.t("automated_tests.autotest_results_job.status.completed");
      }
      break;
    case "queued":
      message_data["notice"] = I18n.t("job.status.queued");
      break;
    case "service_unavailable":
      message_data["notice"] = status_data["exception"]["message"];
      break;
    default:
      message_data["notice"] = I18n.t("automated_tests.autotest_run_job.status.in_progress");
  }
  if (status_data["warning_message"]) {
    message_data["warning"] = status_data["warning_message"];
  }
  return message_data;
}
