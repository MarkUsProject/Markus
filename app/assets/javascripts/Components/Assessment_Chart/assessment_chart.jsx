import React from "react";
import {Bar} from "react-chartjs-2";
import PropTypes from "prop-types";
import {chartScales} from "../Helpers/chart_helpers";
import {CoreStatistics} from "./core_statistics";

export class AssessmentChart extends React.Component {
  render() {
    return (
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
    );
  }
}

AssessmentChart.propTypes = {
  assessment_data: PropTypes.object.isRequired,
  summary: PropTypes.object.isRequired,
  additional_assessment_stats: PropTypes.element.isRequired,
  outstanding_remark_request_link: PropTypes.element,
};
