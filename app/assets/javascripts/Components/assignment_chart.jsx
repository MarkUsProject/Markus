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
        <p>
          <a
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
        </p>
      );
    }

    const assignment_graph = (
      <React.Fragment>
        <h2>
          <a
            href={Routes.browse_course_assignment_submissions_path(
              this.props.course_id,
              this.props.assessment_id
            )}
          >
            {this.state.summary.name}
          </a>
        </h2>
        <div className="flex-row">
          <div>
            <Bar
              data={this.state.assignment_grade_distribution.data}
              options={this.state.assignment_grade_distribution.options}
              width="500"
              height="450"
            />
          </div>
          <div className="flex-row-expand">
            <div className="grid-2-col">
              <span>{I18n.t("average")}</span>
              <span>{(this.state.summary.average || 0).toFixed(2)}%</span>
              <span>{I18n.t("median")}</span>
              <span>{(this.state.summary.median || 0).toFixed(2)}%</span>
              <span>{I18n.t("assignments_submitted")}</span>
              <span>
                {this.state.summary.num_submissions_collected} / {this.state.summary.groupings_size}
              </span>
              <span>{I18n.t("assignments_graded")}</span>
              <span>
                {this.state.summary.num_submissions_graded} / {this.state.summary.groupings_size}
              </span>
              <span>{I18n.t("num_failed")}</span>
              <span>{this.state.summary.num_fails}</span>
              <span>{I18n.t("num_zeros")}</span>
              <span>{this.state.summary.num_zeros}</span>
            </div>
            {outstanding_remark_request_link}
            <p>
              <a
                data-remote="true"
                href={Routes.view_summary_course_assignment_path(
                  this.props.course_id,
                  this.props.assessment_id
                )}
              >
                {I18n.t("refresh")}
              </a>
            </p>
          </div>
        </div>
      </React.Fragment>
    );

    if (this.state.ta_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          {assignment_graph}
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
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          {assignment_graph}
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
        </React.Fragment>
      );
    }
  }
}
