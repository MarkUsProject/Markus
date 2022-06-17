import React from "react";
import {Bar} from "react-chartjs-2";

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

        this.setState({
          summary: res.summary,
          assignment_grade_distribution: {
            ...this.state.assignment_grade_distribution,
            data: res.assignment_data,
          },
          ta_grade_distribution: {
            ...this.state.ta_grade_distribution,
            data: res.ta_data,
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
    if (this.state.summary.num_outstanding_remark_requests > 0) {
      outstanding_remark_request_link = (
        <React.Fragment>
          <a
            className="summary-stats-label"
            href={Routes.browse_course_assignment_submissions_path(
              this.props.course_id,
              this.props.assessment_id,
              {
                filter_by: "marking_state",
                filter_value: "remark",
              }
            )}
          >
            {I18n.t("outstanding_remark_request", {
              count: this.state.summary.num_outstanding_remark_requests,
            })}
          </a>
          <span>
            {this.state.summary.num_remark_requests_completed} /{" "}
            {this.state.summary.num_remark_requests}
          </span>
        </React.Fragment>
      );
    }

    const renderFractionStat = (a, b) => {
      return (
        <span>
          {a} / {b} ({((a / b || 0) * 100).toFixed(2)}%)
        </span>
      );
    };

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
              <span className="summary-stats-label">{I18n.t("assignments_submitted")}</span>
              <span>
                {renderFractionStat(
                  this.state.summary.num_submissions_collected,
                  this.state.summary.groupings_size
                )}
              </span>
              <span className="summary-stats-label">{I18n.t("assignments_graded")}</span>
              <span>
                {renderFractionStat(
                  this.state.summary.num_submissions_graded,
                  this.state.summary.groupings_size
                )}
              </span>
              <span className="summary-stats-label">{"Number of Groups"}</span>
              <span>{this.state.summary.groupings_size}</span>
              <span className="summary-stats-label">{I18n.t("average")}</span>
              <span>
                {renderFractionStat(
                  (this.state.summary.average_mark || 0).toFixed(2),
                  this.state.summary.max_mark
                )}
              </span>
              <span className="summary-stats-label">{I18n.t("median")}</span>
              <span>
                {renderFractionStat(this.state.summary.median_mark, this.state.summary.max_mark)}
              </span>
              <span className="summary-stats-label">{"Standard Deviation"}</span>
              <span>{(this.state.summary.standard_deviation || 0).toFixed(2)} σ</span>
              <span className="summary-stats-label">{I18n.t("num_failed")}</span>
              <span>
                {renderFractionStat(
                  this.state.summary.num_fails,
                  this.state.summary.groupings_size
                )}
              </span>
              <span className="summary-stats-label">{I18n.t("num_zeros")}</span>
              <span>
                {renderFractionStat(
                  this.state.summary.num_zeros,
                  this.state.summary.groupings_size
                )}
              </span>
              {outstanding_remark_request_link}
            </div>
          </div>
        </div>
      </React.Fragment>
    );

    if (this.state.ta_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          {assignment_graph}
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
