import React from "react";
import {render} from "react-dom";
import {Bar} from "react-chartjs-2";
import {chartScales} from "./Helpers/chart_helpers";

export const DEFAULT_ASSESSMENT_STATE = {
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

export function setAssessmentState(res, component) {
  component.setState({
    summary: res.summary,
    assessment_grade_distribution: {
      ...component.state.assessment_grade_distribution,
      data: res.assessment_data,
    },
    secondary_grade_distribution: {
      ...component.state.secondary_grade_distribution,
      data: res.secondary_assessment_data,
    },
  });
  for (const [index, element] of res.secondary_assessment_data.datasets.entries()) {
    element.backgroundColor = colours[index];
  }
}

export class AssessmentGraph extends React.Component {
  render() {
    const assessment_options = {
      scales: chartScales(),
    };
    return (
      <React.Fragment>
        <div className="flex-row">
          <div className="distribution-graph">
            <h3>{I18n.t("grade_distribution")}</h3>
            <Bar
              data={this.props.chart_data}
              options={assessment_options}
              width="500"
              height="450"
            />
          </div>
          <div className="flex-row-expand">
            <div className="grid-2-col">
              {this.props.additional_assessment_data}
              <CoreStatistics
                average={this.props.summary.average}
                median={this.props.summary.median}
                standard_deviation={this.props.summary.standard_deviation}
                max_mark={this.props.summary.max_mark}
                num_fails={this.props.summary.num_fails}
                num_zeros={this.props.summary.num_zeros}
                num_groupings={this.props.summary.groupings_size}
              />
              {this.props.outstanding_remark_request_link}
            </div>
          </div>
        </div>
      </React.Fragment>
    );
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
