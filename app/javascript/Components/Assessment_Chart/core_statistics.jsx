import {FractionStat} from "./fraction_stat";
import PropTypes from "prop-types";

export function CoreStatistics({
  average,
  max_mark,
  median,
  num_fails,
  num_groupings,
  num_zeros,
  standard_deviation,
}) {
  const max_mark_value = Number(max_mark) || 0;
  let percent_standard_deviation = "0.00";
  if (max_mark_value !== 0) {
    percent_standard_deviation = (
      (100 / max_mark_value) *
      (Number(standard_deviation) || 0)
    ).toFixed(2);
  }
  let num_fails_stat = "";
  if (num_fails !== undefined) {
    num_fails_stat = (
      <>
        <span className="summary-stats-label">{I18n.t("num_failed")}</span>
        <FractionStat numerator={num_fails} denominator={num_groupings} />
      </>
    );
  }

  return (
    <>
      <span className="summary-stats-label">{I18n.t("average")}</span>
      <FractionStat numerator={average} denominator={max_mark} />
      <span className="summary-stats-label">{I18n.t("median")}</span>
      <FractionStat numerator={median} denominator={max_mark} />
      <span className="summary-stats-label">{I18n.t("standard_deviation")}</span>
      <span>
        {(standard_deviation || 0).toFixed(2)}
        &nbsp;({percent_standard_deviation}%)
      </span>
      {num_fails_stat}
      <span className="summary-stats-label">{I18n.t("num_zeros")}</span>
      <FractionStat numerator={num_zeros} denominator={num_groupings} />
    </>
  );
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
