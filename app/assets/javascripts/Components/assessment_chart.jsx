import React from "react";
import {Bar} from "react-chartjs-2";
import PropTypes from "prop-types";
import {chartScales} from "./Helpers/chart_helpers";
import ReactTable from "react-table";

class AssessmentChart extends React.Component {
  render() {
    const assessment_graph = (
      <React.Fragment>
        <div className="flex-row">
          <div className="distribution-graph">
            <h3>{I18n.t("grade_distribution")}</h3>
            <Bar
              data={this.props.assessment_data}
              options={{scales: chartScales()}}
              width="500"
              height="450"
            />
          </div>
          <div className="flex-row-expand">
            <div className="grid-2-col">
              {this.props.additional_assessment_stats}
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

    let grade_breakdown_graph = "";
    if (this.props.show_grade_breakdown_chart && this.props.grade_breakdown_summary.length > 0) {
      const grade_breakdown_graph_options = {
        plugins: {
          legend: {
            display: true,
            labels: {
              // Ensure criteria / grade entry item labels are sorted in position order
              sort: (a, b) => {
                const itemA = this.props.grade_breakdown_summary.find(item => item.name === a.text);
                const itemB = this.props.grade_breakdown_summary.find(item => item.name === b.text);
                return itemA.position - itemB.position;
              },
            },
          },
        },
        scales: chartScales(),
      };
      let grade_breakdown_summary_table = "";
      if (this.props.show_grade_breakdown_table) {
        grade_breakdown_summary_table = (
          <div className="flex-row-expand">
            <div className="criteria-summary-table">
              <ReactTable
                data={this.props.grade_breakdown_summary}
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
                      num_groupings={this.props.grade_breakdown_summary.groupings_size}
                    />
                  </div>
                )}
              />
            </div>
          </div>
        );
      }
      grade_breakdown_graph = (
        <div className="flex-row">
          <div className="grade-breakdown-graph">
            <h3>{this.props.grade_breakdown_distribution_title}</h3>
            <Bar
              data={this.props.grade_breakdown_distribution_data}
              options={grade_breakdown_graph_options}
              width="400"
              height="350"
            />
          </div>
          {grade_breakdown_summary_table}
        </div>
      );
    } else if (this.props.show_grade_breakdown_chart) {
      grade_breakdown_graph = (
        <div className="grade-breakdown-graph">
          <h3>{this.props.grade_breakdown_distribution_title}</h3>
          <h4>({this.props.grade_breakdown_assign_link})</h4>
        </div>
      );
    }

    return (
      <React.Fragment>
        <h2>{this.props.assessment_header_content}</h2>
        {assessment_graph}
        {grade_breakdown_graph}
      </React.Fragment>
    );
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

AssessmentChart.propTypes = {
  assessment_header_content: PropTypes.element.isRequired,
  assessment_data: PropTypes.object.isRequired,
  summary: PropTypes.object.isRequired,
  additional_assessment_stats: PropTypes.element.isRequired,
  outstanding_remark_request_link: PropTypes.element,
  show_grade_breakdown_chart: PropTypes.bool.isRequired,
  show_grade_breakdown_table: PropTypes.bool.isRequired,
  grade_breakdown_summary: PropTypes.array,
  grade_breakdown_distribution_data: PropTypes.object,
  grade_breakdown_assign_link: PropTypes.element,
};

export {AssessmentChart, FractionStat};
