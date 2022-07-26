import React from "react";
import {Bar} from "react-chartjs-2";
import ReactTable from "react-table";
import PropTypes from "prop-types";
import {chartScales} from "./Helpers/chart_helpers";

export class AssessmentChart extends React.Component {
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
      assessment_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          scales: chartScales(),
        },
      },
      column_ta_grade_distribution: {
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
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    let fetch_route = "";
    if (this.props.assessment_type === "Assignment") {
      fetch_route = Routes.grade_distribution_course_assignment_path;
    } else if (this.props.assessment_type === "GradeEntryForm") {
      fetch_route = Routes.grade_distribution_course_grade_entry_form_path;
    }
    fetch(
      fetch_route(this.props.course_id, this.props.assessment_id, {
        get_criteria_data: this.props.show_criteria_stats,
      })
    )
      .then(data => data.json())
      .then(res => {
        this.setState({
          summary: res.summary,
          assessment_grade_distribution: {
            ...this.state.assessment_grade_distribution,
            data: res.assessment_data,
          },
        });
        const set_graph_data = (data, distribution_state) => {
          for (const [index, element] of data.datasets.entries()) {
            element.backgroundColor = colours[index];
          }
          this.setState(distribution_state);
        };

        if (this.props.assessment_type === "GradeEntryForm") {
          set_graph_data(res.column_breakdown_data, {
            column_ta_grade_distribution: {
              ...this.state.column_ta_grade_distribution,
              data: res.column_breakdown_data,
            },
          });
        } else if (this.props.assessment_type === "Assignment") {
          set_graph_data(res.ta_data, {
            column_ta_grade_distribution: {
              ...this.state.column_ta_grade_distribution,
              data: res.ta_data,
            },
          });

          if (this.props.show_criteria_stats) {
            set_graph_data(res.criteria_data, {
              criteria_summary: res.criteria_summary,
              criteria_grade_distribution: {
                ...this.state.criteria_grade_distribution,
                data: res.criteria_data,
              },
            });
          }
        }
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
    if (this.props.assessment_type === "Assignment" && this.state.summary.remark_requests_enabled) {
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

    let assessment_data = "";
    if (this.props.assessment_type === "Assignment") {
      assessment_data = (
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
      );
    } else if (this.props.assessment_type === "GradeEntryForm") {
      assessment_data = (
        <React.Fragment>
          <span className="summary-stats-label">{I18n.t("attributes.date")}</span>
          <span>{this.state.summary.date}</span>
          <span className="summary-stats-label">{I18n.t("num_entries")}</span>
          <FractionStat
            numerator={this.state.summary.num_entries}
            denominator={this.state.summary.groupings_size}
          />
        </React.Fragment>
      );
    }

    const assessment_graph = (
      <React.Fragment>
        <div className="flex-row">
          <div className="distribution-graph">
            <h3>{I18n.t("grade_distribution")}</h3>
            <Bar
              data={this.state.assessment_grade_distribution.data}
              options={this.state.assessment_grade_distribution.options}
              width="500"
              height="450"
            />
          </div>
          <div className="flex-row-expand">
            <div className="grid-2-col">
              {assessment_data}
              <CoreStatistics
                average={this.state.summary.average}
                median={this.state.summary.median}
                standard_deviation={this.state.summary.standard_deviation}
                max_mark={this.state.summary.max_mark}
                num_fails={this.state.summary.num_fails}
                num_zeros={this.state.summary.num_zeros}
                num_groupings={this.state.summary.groupings_size}
              />
              {outstanding_remark_request_link}
            </div>
          </div>
        </div>
      </React.Fragment>
    );

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

    if (this.state.column_ta_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          {assessment_graph}
          {criteria_graph}
          <div className="distribution-graph">
            <h3>{I18n.t("grader_distribution")}</h3>
            <Bar
              data={this.state.column_ta_grade_distribution.data}
              options={this.state.column_ta_grade_distribution.options}
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
          {assessment_graph}
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
    const max_mark_value = Number(this.props.max_mark) || 0;
    let percent_standard_deviation = "0.00";
    if (max_mark_value !== 0) {
      percent_standard_deviation = (
        (100 / max_mark_value) *
        (Number(this.props.standard_deviation) || 0)
      ).toFixed(2);
    }
    let num_fails = "";
    if (this.props.num_fails !== undefined) {
      num_fails = (
        <React.Fragment>
          <span className="summary-stats-label">{I18n.t("num_failed")}</span>
          <FractionStat numerator={this.props.num_fails} denominator={this.props.num_groupings} />
        </React.Fragment>
      );
    }

    return (
      <React.Fragment>
        <span className="summary-stats-label">{I18n.t("average")}</span>
        <FractionStat numerator={this.props.average} denominator={this.props.max_mark} />
        <span className="summary-stats-label">{I18n.t("median")}</span>
        <FractionStat numerator={this.props.median} denominator={this.props.max_mark} />
        <span className="summary-stats-label">{I18n.t("standard_deviation")}</span>
        <span>
          {(this.props.standard_deviation || 0).toFixed(2)}
          &nbsp;({percent_standard_deviation}%)
        </span>
        {num_fails}
        <span className="summary-stats-label">{I18n.t("num_zeros")}</span>
        <FractionStat numerator={this.props.num_zeros} denominator={this.props.num_groupings} />
      </React.Fragment>
    );
  }
}

CoreStatistics.propTypes = {
  average: PropTypes.number.isRequired,
  median: PropTypes.number.isRequired,
  standard_deviation: PropTypes.number.isRequired,
  max_mark: PropTypes.number.isRequired,
  num_fails: PropTypes.number,
  num_zeros: PropTypes.number.isRequired,
  num_groupings: PropTypes.number.isRequired,
};
