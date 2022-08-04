import React from "react";
import {Bar} from "react-chartjs-2";
import PropTypes from "prop-types";
import {chartScales} from "./Helpers/chart_helpers";

export class AssessmentChart extends React.Component {
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

    if (this.props.secondary_grade_distribution_data.datasets.length !== 0) {
      const secondary_grade_chart_options = {
        plugins: {
          legend: {
            display: true,
          },
        },
        scales: chartScales(),
      };
      return (
        <React.Fragment>
          <h2>{this.props.assessment_header_content}</h2>
          {assessment_graph}
          {this.props.criteria_graph}
          <div className="distribution-graph">
            <h3>{this.props.secondary_grade_distribution_title}</h3>
            <Bar
              data={this.props.secondary_grade_distribution_data}
              options={secondary_grade_chart_options}
              width="400"
              height="350"
            />
            {this.props.secondary_grade_distribution_link}
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
            {this.props.secondary_grade_distribution_link}
          </div>
        </React.Fragment>
      );
    }
  }
}

AssessmentChart.propTypes = {
  course_id: PropTypes.number.isRequired,
  assessment_id: PropTypes.number.isRequired,
  assessment_header_content: PropTypes.element.isRequired,
  summary: PropTypes.shape({
    average: PropTypes.number.isRequired,
    median: PropTypes.number.isRequired,
    num_submissions_collected: PropTypes.number.isRequired,
    num_submissions_graded: PropTypes.number.isRequired,
    num_fails: PropTypes.number.isRequired,
    num_zeros: PropTypes.number.isRequired,
    groupings_size: PropTypes.number.isRequired,
  }),
  assessment_data: PropTypes.exact({
    labels: PropTypes.array.isRequired,
    datasets: PropTypes.array.isRequired,
  }),
  additional_assessment_stats: PropTypes.element.isRequired,
  outstanding_remark_request_link: PropTypes.element,
  secondary_grade_distribution_title: PropTypes.string.isRequired,
  secondary_grade_distribution_data: PropTypes.exact({
    labels: PropTypes.array.isRequired,
    datasets: PropTypes.array.isRequired,
  }),
  criteria_graph: PropTypes.element,
  secondary_grade_distribution_link: PropTypes.element,
};
