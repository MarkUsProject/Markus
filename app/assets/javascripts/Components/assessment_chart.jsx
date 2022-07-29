import React from "react";
import {Bar} from "react-chartjs-2";
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
      assessment_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          scales: chartScales(),
        },
      },
      // Grade distribution for either the TA or column grade distribution breakdown
      secondary_grade_distribution: {
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
    this.props.fetch_data((summary, assessment_data, secondary_assessment_data) => {
      this.setState({
        summary: summary,
        assessment_grade_distribution: {
          ...this.state.assessment_grade_distribution,
          data: assessment_data,
        },
      });
      for (const [index, element] of secondary_assessment_data.datasets.entries()) {
        element.backgroundColor = colours[index];
      }
      this.setState({
        secondary_grade_distribution: {
          ...this.state.secondary_grade_distribution,
          data: secondary_assessment_data,
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
              {this.props.additional_assessment_data}
              <CoreStatistics
                average={this.state.summary.average}
                median={this.state.summary.median}
                standard_deviation={this.state.summary.standard_deviation}
                max_mark={this.state.summary.max_mark}
                num_fails={this.state.summary.num_fails}
                num_zeros={this.state.summary.num_zeros}
                num_groupings={this.state.summary.groupings_size}
              />
              {this.props.outstanding_remark_request_link}
            </div>
          </div>
        </div>
      </React.Fragment>
    );

    if (this.state.secondary_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          <h2>{this.props.assessment_header_content}</h2>
          {assessment_graph}
          {this.props.criteria_graph}
          <div className="distribution-graph">
            <h3>{this.props.secondary_grade_distribution_title}</h3>
            <Bar
              data={this.state.secondary_grade_distribution.data}
              options={this.state.secondary_grade_distribution.options}
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
          <h2>{this.props.assessment_header_content}</h2>
          {assessment_graph}
          {this.props.criteria_graph}
          <div className="distribution-graph">
            <h3>{this.props.secondary_grade_distribution_title}</h3>
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

export class FractionStat extends React.Component {
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

export class CoreStatistics extends React.Component {
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

AssessmentChart.propTypes = {
  assessment_header_content: PropTypes.element.isRequired,
  fetch_data: PropTypes.func.isRequired,
  secondary_grade_distribution_title: PropTypes.string.isRequired,
  additional_assessment_data: PropTypes.element.isRequired,
  course_id: PropTypes.number.isRequired,
  assessment_id: PropTypes.number.isRequired,
  criteria_graph: PropTypes.element,
  outstanding_remark_request_link: PropTypes.element,
};
