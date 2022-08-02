import React from "react";
import ReactTable from "react-table";
import {Bar} from "react-chartjs-2";
import {AssessmentChart, CoreStatistics, FractionStat} from "./assessment_chart";
import {chartScales} from "./Helpers/chart_helpers";

export class AssignmentChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: [],
      criteria_summary: [],
      criteria_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          plugins: {
            legend: {
              display: true,
              labels: {
                // Ensure criteria labels are sorted in position order
                sort: (a, b) => {
                  const itemA = this.state.criteria_summary.find(item => item.name === a.text);
                  const itemB = this.state.criteria_summary.find(item => item.name === b.text);
                  return itemA.position - itemB.position;
                },
              },
            },
          },
          scales: chartScales(),
        },
      },
      show_grader_summary_link: false,
    };
  }

  configureComponent = res => {
    this.setState({
      summary: res.summary,
      show_grader_summary_link: res.secondary_grade_distribution.data.datasets.length !== 0,
    });
    if (this.props.show_criteria_stats) {
      for (const [index, element] of res.criteria_data.datasets.entries()) {
        element.backgroundColor = colours[index];
      }
      this.setState({
        criteria_summary: res.criteria_summary,
        criteria_grade_distribution: {
          ...this.state.criteria_grade_distribution,
          data: res.criteria_data,
        },
      });
    }
  };

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

    let criteria_graph = "";
    if (this.props.show_criteria_stats && this.state.criteria_summary.length > 0) {
      criteria_graph = (
        <div className="flex-row">
          <div className="distribution-graph">
            <h3>{I18n.t("criteria_grade_distribution")}</h3>
            <Bar
              data={this.state.criteria_grade_distribution.data}
              options={this.state.criteria_grade_distribution.options}
              width="400"
              height="350"
            />
          </div>
          <div className="flex-row-expand">
            <div className="criteria-summary-table">
              <ReactTable
                data={this.state.criteria_summary}
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
                defaultSorted={[{id: "position"}]}
                SubComponent={row => (
                  <div className="criteria-stat-breakdown grid-2-col">
                    <CoreStatistics
                      average={row.original.average}
                      median={row.original.median}
                      standard_deviation={row.original.standard_deviation}
                      max_mark={row.original.max_mark}
                      num_zeros={row.original.num_zeros}
                      num_groupings={this.state.summary.groupings_size}
                    />
                  </div>
                )}
              />
            </div>
          </div>
        </div>
      );
    } else if (this.props.show_criteria_stats) {
      criteria_graph = (
        <div className="distribution-graph">
          <h3>{I18n.t("criteria_grade_distribution")}</h3>
          <h4>
            (
            <a
              href={Routes.course_assignment_criteria_path(
                this.props.course_id,
                this.props.assessment_id
              )}
            >
              {I18n.t("helpers.submit.create", {
                model: I18n.t("activerecord.models.criterion.one"),
              })}
            </a>
            )
          </h4>
        </div>
      );
    }

    let secondary_grade_distribution_link = (
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
    );
    if (this.state.show_grader_summary_link) {
      secondary_grade_distribution_link = (
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
      );
    }

    return (
      <AssessmentChart
        course_id={this.props.course_id}
        assessment_id={this.props.assessment_id}
        fetch_url={Routes.grade_distribution_course_assignment_path(
          this.props.course_id,
          this.props.assessment_id,
          {
            get_criteria_data: this.props.show_criteria_stats,
          }
        )}
        configChart={this.configureComponent}
        assessment_header_content={
          <a
            href={Routes.browse_course_assignment_submissions_path(
              this.props.course_id,
              this.props.assessment_id
            )}
          >
            {this.state.summary.name}
          </a>
        }
        additional_assessment_data={
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
        criteria_graph={criteria_graph}
        secondary_grade_distribution_link={secondary_grade_distribution_link}
      />
    );
  }
}
