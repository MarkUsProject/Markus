import React from "react";
import {Bar} from "react-chartjs-2";
import ReactTable from "react-table";
import {chartScales} from "./Helpers/chart_helpers";

export class AssignmentChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: null,
        median: null,
        num_submissions_collected: null,
        num_submissions_graded: null,
        num_fails: null,
        num_zeros: null,
        groupings_size: null,
      },
      criteria_summary: [],
      assignment_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          scales: chartScales(),
        },
      },
      ta_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          plugins: {
            legend: {
              display: true,
            },
          },
          scales: chartScales(),
        },
      },
      criteria_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          plugins: {
            legend: {
              display: true,
            },
          },
          scales: chartScales(),
        },
      },
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.grade_distribution_course_assignment_path(
        this.props.course_id,
        this.props.assessment_id
      )
    )
      .then(data => data.json())
      .then(res => {
        // Load in background colours
        for (const [index, element] of res.ta_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }
        for (const [index, element] of res.criteria_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }

        this.setState({
          summary: res.summary,
          criteria_summary: res.criteria_summary,
          assignment_grade_distribution: {
            ...this.state.assignment_grade_distribution,
            data: res.assignment_data,
          },
          ta_grade_distribution: {
            ...this.state.ta_grade_distribution,
            data: res.ta_data,
          },
          criteria_grade_distribution: {
            ...this.state.criteria_grade_distribution,
            data: res.criteria_data,
          },
        });

        if (typeof this.props.set_assessment_name === "function") {
          this.props.set_assessment_name(res.summary.name);
        }
      });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }

  render() {
    let outstanding_remark_request_link = "";
    if (this.state.summary.remark_requests_enabled) {
      const remark_submissions_list_link = Routes.browse_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assessment_id,
        {
          filter_by: "marking_state",
          filter_value: "remark",
        }
      );
      outstanding_remark_request_link = (
        <React.Fragment>
          <a className="summary-stats-label" href={remark_submissions_list_link}>
            {I18n.t("remark_requests_completed")}
          </a>
          <a href={remark_submissions_list_link}>
            <FractionStat
              numerator={this.state.summary.num_remark_requests_completed}
              denominator={this.state.summary.num_remark_requests}
            />
          </a>
        </React.Fragment>
      );
    }

    const assignment_graph = (
      <React.Fragment>
        <div className="flex-row">
          <div className="distribution-graph">
            <h3>{I18n.t("grade_distribution")}</h3>
            <Bar
              data={this.state.assignment_grade_distribution.data}
              options={this.state.assignment_grade_distribution.options}
              width="500"
              height="450"
            />
          </div>
          <div className="flex-row-expand">
            <div className="grid-2-col">
              <span className="summary-stats-label">{I18n.t("num_groups")}</span>
              <span>{this.state.summary.groupings_size}</span>
              <span className="summary-stats-label">{I18n.t("num_students_in_group")}</span>
              <FractionStat
                numerator={this.state.summary.num_students_in_group}
                denominator={this.state.summary.num_active_students}
              />
              <span className="summary-stats-label">{I18n.t("assignments_submitted")}</span>
              <FractionStat
                numerator={this.state.summary.num_submissions_collected}
                denominator={this.state.summary.groupings_size}
              />
              <span className="summary-stats-label">{I18n.t("assignments_graded")}</span>
              <FractionStat
                numerator={this.state.summary.num_submissions_graded}
                denominator={this.state.summary.groupings_size}
              />
              <CoreStatistics
                average={this.state.summary.average}
                median={this.state.summary.median}
                standard_deviation={this.state.summary.standard_deviation}
                max_mark={this.state.summary.max_mark}
                num_fails={this.state.summary.num_fails}
                num_groupings={this.state.summary.num_groupings}
              />
              {outstanding_remark_request_link}
            </div>
          </div>
        </div>
      </React.Fragment>
    );

    let criteria_graph = "";
    if (this.props.show_criteria_stats) {
      criteria_graph = (
        <React.Fragment>
          <div className="flex-row">
            <div className="distribution-graph">
              <h3>{I18n.t("criteria_distribution")}</h3>
              <Bar
                data={this.state.criteria_grade_distribution.data}
                options={this.state.criteria_grade_distribution.options}
                width="400"
                height="350"
              />
            </div>
            <div className="flex-row-expand">
              <CriteriaStatsTable
                data={this.state.criteria_summary}
                num_groupings={this.state.summary.groupings_size}
                criteria_labels={this.state.criteria_grade_distribution.data.labels}
              />
            </div>
          </div>
        </React.Fragment>
      );
    }

    if (this.state.ta_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          {assignment_graph}
          {criteria_graph}
          <div className="distribution-graph">
            <h3>{I18n.t("grader_distribution")}</h3>
            <Bar
              data={this.state.ta_grade_distribution.data}
              options={this.state.ta_grade_distribution.options}
              width="400"
              height="350"
            />
            <p>
              <a
                href={Routes.grader_summary_course_assignment_graders_path(
                  this.props.course_id,
                  this.props.assessment_id
                )}
              >
                {I18n.t("activerecord.models.ta.other")}
              </a>
            </p>
          </div>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          {assignment_graph}
          {criteria_graph}
          <div className="distribution-graph">
            <h3>{I18n.t("grader_distribution")}</h3>
            <h4>
              (
              <a
                href={Routes.course_assignment_graders_path(
                  this.props.course_id,
                  this.props.assessment_id
                )}
              >
                {I18n.t("graders.actions.assign_grader")}
              </a>
              )
            </h4>
          </div>
        </React.Fragment>
      );
    }
  }
}

class FractionStat extends React.Component {
  render() {
    const numerator = +(Number(this.props.numerator) || 0).toFixed(2),
      denominator = +(Number(this.props.denominator) || 0).toFixed(2);
    let result = "0.00";
    if (denominator !== 0) {
      result = ((Number(this.props.numerator) / Number(this.props.denominator) || 0) * 100).toFixed(
        2
      );
    }
    return (
      <span>
        {numerator} / {denominator} ({result}%)
      </span>
    );
  }
}

class CoreStatistics extends React.Component {
  render() {
    const percentage_standard_deviation = () => {
      const max_mark = Number(this.props.max_mark) || 0;
      if (max_mark === 0) {
        return "0.00";
      }
      return ((100 / max_mark) * (Number(this.props.standard_deviation) || 0)).toFixed(2);
    };

    return (
      <React.Fragment>
        <span className="summary-stats-label">{I18n.t("average")}</span>
        <FractionStat numerator={this.props.average} denominator={this.props.max_mark} />
        <span className="summary-stats-label">{I18n.t("median")}</span>
        <FractionStat numerator={this.props.median} denominator={this.props.max_mark} />
        <span className="summary-stats-label">{I18n.t("standard_deviation")}</span>
        <span>
          {(this.props.standard_deviation || 0).toFixed(2)}
          &nbsp;({percentage_standard_deviation()}%)
        </span>
        <span className="summary-stats-label">{I18n.t("num_failed")}</span>
        <FractionStat numerator={this.props.num_fails} denominator={this.props.groupings_size} />
        <span className="summary-stats-label">{I18n.t("num_zeros")}</span>
        <FractionStat numerator={this.props.num_zeros} denominator={this.props.groupings_size} />
      </React.Fragment>
    );
  }
}

class CriteriaStatsTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: false,
    };
  }

  render() {
    return (
      <div className="criteria-summary-table">
        <ReactTable
          data={this.props.data}
          columns={[
            {
              Header: I18n.t("activerecord.models.criterion.one"),
              accessor: "name",
              minWidth: 150,
            },
            {
              Header: I18n.t("average"),
              accessor: "average",
              sortable: false,
              filterable: false,
              Cell: row => (
                <FractionStat
                  numerator={row.original.average}
                  denominator={row.original.max_mark}
                />
              ),
            },
          ]}
          filterable
          defaultSorted={[{id: "name"}]}
          SubComponent={row => (
            <div className="flex-row">
              <div className="distribution-graph">
                <h3> {I18n.t("criteria_distribution")}</h3>
                <Bar
                  data={{
                    labels: this.props.criteria_labels,
                    datasets: [row.original.dataset],
                  }}
                  options={{
                    scales: chartScales(),
                  }}
                  width="400"
                  height="350"
                />
              </div>
              <div className="flex-row-expand">
                <div className="criteria-stat-breakdown">
                  <CoreStatistics
                    average={row.original.average}
                    median={row.original.median}
                    standard_deviation={row.original.standard_deviation}
                    max_mark={row.original.max_mark}
                    num_fails={row.original.num_fails}
                    num_groupings={this.props.num_groupings}
                  />
                </div>
              </div>
            </div>
          )}
          loading={this.state.loading}
        />
      </div>
    );
  }
}
