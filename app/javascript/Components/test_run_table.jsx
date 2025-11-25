import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {dateSort} from "./Helpers/table_helpers";
import consumer from "../channels/consumer";
import {renderFlashMessages} from "../common/flash";
import {TestGroupResultTable} from "./test_group_result_table";

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
