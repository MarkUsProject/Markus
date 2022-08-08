import React from "react";
import {Bar} from "react-chartjs-2";
import ReactTable from "react-table";
import {AssessmentChart, CoreStatistics, FractionStat} from "./assessment_chart";
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
      },
      ta_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
      },
      criteria_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
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
        this.props.assessment_id,
        {get_criteria_data: this.props.show_criteria_stats}
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
            data: res.assignment_data,
          },
          ta_grade_distribution: {
            data: res.ta_data,
          },
        });

        if (this.props.show_criteria_stats) {
          for (const [index, element] of res.criteria_data.datasets.entries()) {
            element.backgroundColor = colours[index];
          }
          this.setState({
            criteria_summary: res.criteria_summary,
            criteria_grade_distribution: {
              data: res.criteria_data,
            },
          });
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

    let ta_grade_distribution_chart = (
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
    );
    if (this.state.ta_grade_distribution.data.datasets.length !== 0) {
      const ta_grade_chart_options = {
        plugins: {
          legend: {
            display: true,
          },
        },
        scales: chartScales(),
      };
      ta_grade_distribution_chart = (
        <div className="distribution-graph">
          <h3>{I18n.t("criteria_grade_distribution")}</h3>
          <Bar
            data={this.state.ta_grade_distribution.data}
            options={ta_grade_chart_options}
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
      );
    }

    return (
      <AssessmentChart
        course_id={this.props.course_id}
        assessment_id={this.props.assessment_id}
        assessment_header_content={
          <a
            href={Routes.browse_course_assignment_submissions_path(
              this.props.course_id,
              this.props.assessment_id
            )}
          >
            {this.props.show_chart_header ? this.state.summary.name : ""}
          </a>
        }
        summary={this.state.summary}
        assessment_data={this.state.assignment_grade_distribution.data}
        additional_assessment_stats={
          <React.Fragment>
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
          </React.Fragment>
        }
        outstanding_remark_request_link={outstanding_remark_request_link}
        secondary_grade_distribution_title={I18n.t("grader_distribution")}
        secondary_grade_distribution_data={this.state.ta_grade_distribution.data}
        secondary_grade_distribution_link={ta_grade_distribution_link}
      />
    );
  }
}
