import React from "react";
import {createRoot} from "react-dom/client";
import ReactTable from "react-table";
import {dateSort} from "./Helpers/table_helpers";

const makeDefaultState = () => ({
  data: [],
  statuses: {},
  loading: true,
});

class BatchTestRunTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
    this.processData = this.processData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    fetch(
      Routes.batch_runs_course_assignment_path(this.props.course_id, this.props.assignment_id),
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
        this.processData(res);
      });
  }

  processData(data) {
    let status = {};
    data.forEach(row => {
      if (!(row.test_batch_id in status)) {
        status[row.test_batch_id] = {total: 0, in_progress: 0};
      }
      const result_url = Routes.edit_course_result_path(this.props.course_id, row.result_id);
      row.group_name = <a href={result_url}>{row.group_name}</a>;

      if (row.status === "in_progress") {
        const stop_tests_url = Routes.stop_test_course_assignment_path(
          this.props.course_id,
          this.props.assignment_id
        );
        row.action = (
          <a href={stop_tests_url + "?test_run_id=" + row.id}>
            {I18n.t("automated_tests.stop_test")}
          </a>
        );
        // increment in_progress number for this batch_id
        status[row.test_batch_id].in_progress += 1;
        row.status = I18n.t("automated_tests.test_runs_statuses.in_progress");
      } else {
        row.time_to_completion = "";
        row.action = "";
      }
      status[row.test_batch_id].total += 1;
    });
    this.setState({
      data: data,
      statuses: status,
      loading: false,
    });
  }

  render() {
    // Set the row map to expand the latest test run when the webpage is loaded
    return (
      <div>
        <ReactTable
          data={this.state.data}
          columns={[
            {
              Header: I18n.t("activerecord.attributes.test_batch.created_at"),
              accessor: "created_at",
              minWidth: 120,
              sortMethod: dateSort,
              PivotValue: ({value}) => value,
            },
            {
              Header: I18n.t("activerecord.attributes.group.group_name"),
              accessor: "group_name",
              // If more than one value, show the total number of groups under this pivot
              aggregate: vals => {
                if (typeof vals[1] === "undefined") {
                  return vals[0];
                } else {
                  const numGroups = Object.keys(vals).length;
                  return numGroups + " " + I18n.t("activerecord.models.group", {count: numGroups});
                }
              },
              sortable: true,
            },
            {
              Header: I18n.t("activerecord.attributes.test_run.status"),
              accessor: "status",
              minWidth: 70,
              aggregate: (vals, pivots) => {
                const batch = this.state.statuses[pivots[0].test_batch_id];
                if (pivots[0].test_batch_id === null) {
                  return `${pivots[0].status}`;
                } else {
                  const total = batch.total;
                  const complete = total - batch.in_progress;
                  return `${complete} / ${total} ${I18n.t("poll_job.completed")}`;
                }
              },
              sortable: false,
              Aggregated: row => <span>{row.value}</span>,
            },
            {
              Header: I18n.t("actions"),
              accessor: "action",
              minWidth: 70,
              sortable: false,
              aggregate: (vals, pivots) => {
                return [
                  pivots[0].test_batch_id,
                  this.state.statuses[pivots[0].test_batch_id],
                  pivots[0].action,
                ];
              },
              Aggregated: row => {
                if (row.value[1].in_progress > 0) {
                  if (row.value[0] === null) {
                    return row.value[2];
                  } else {
                    const stop_tests_url = Routes.stop_batch_tests_course_assignment_path(
                      this.props.course_id,
                      this.props.assignment_id
                    );
                    return (
                      <span>
                        <a href={stop_tests_url + "?test_batch_id=" + row.value[0]}>
                          {I18n.t("automated_tests.stop_batch")}
                        </a>
                      </span>
                    );
                  }
                } else {
                  return "";
                }
              },
            },
            {
              // Kept but hidden because status is using it
              Header: "",
              accessor: "test_batch_id",
              show: false,
            },
          ]}
          pivotBy={["created_at"]}
          defaultSorted={[{id: "created_at", desc: true}]}
          loading={this.state.loading}
        />
      </div>
    );
  }
}

export function makeBatchTestRunTable(elem, props) {
  const root = createRoot(elem);
  const component = React.createRef();
  root.render(<BatchTestRunTable {...props} ref={component} />);
  return component;
}
