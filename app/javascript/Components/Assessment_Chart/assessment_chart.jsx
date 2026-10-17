import {Bar} from "react-chartjs-2";
import PropTypes from "prop-types";
import {chartScales} from "../Helpers/chart_helpers";
import {CoreStatistics} from "./core_statistics";

export function AssessmentChart({
  additional_assessment_stats,
  assessment_data,
  outstanding_remark_request_link,
  summary,
}) {
  return (
    <div className="flex-row">
      <div className="distribution-graph">
        <h3>{I18n.t("grade_distribution")}</h3>
        <Bar data={assessment_data} options={{scales: chartScales()}} width="500" height="450" />
      </div>
      <div className="flex-row-expand">
        <div className="grid-2-col">
          {additional_assessment_stats}
          <CoreStatistics
            average={summary.average}
            median={summary.median}
            standard_deviation={summary.standard_deviation}
            max_mark={summary.max_mark}
            num_fails={summary.num_fails}
            num_zeros={summary.num_zeros}
            num_groupings={summary.groupings_size}
          />
          {outstanding_remark_request_link}
        </div>
      </div>
    </div>
  );
}

AssessmentChart.propTypes = {
  assessment_data: PropTypes.object.isRequired,
  summary: PropTypes.object.isRequired,
  additional_assessment_stats: PropTypes.element.isRequired,
  outstanding_remark_request_link: PropTypes.element,
};
