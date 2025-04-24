import React from "react";
import {Bar} from "react-chartjs-2";
import {chartScales} from "../Helpers/chart_helpers";
import ReactTable from "react-table";
import PropTypes from "prop-types";
import {CoreStatistics} from "./core_statistics";
import {FractionStat} from "./fraction_stat";

export class GradeBreakdownChart extends React.Component {
  render() {
    let summary_table = "";
    if (this.props.show_stats) {
      summary_table = (
        <div className="flex-row-expand">
          <div className="grade-breakdown-summary-table">
            <ReactTable
              data={this.props.summary}
              columns={[
                {
                  Header: this.props.item_name,
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
                <div className="grade-stats-breakdown grid-2-col">
                  <CoreStatistics
                    average={row.original.average}
                    median={row.original.median}
                    standard_deviation={row.original.standard_deviation}
                    max_mark={row.original.max_mark}
                    num_zeros={row.original.num_zeros}
                    num_groupings={this.props.num_groupings}
                  />
                </div>
              )}
            />
          </div>
        </div>
      );
    }

    if (this.props.summary.length > 0) {
      const graph_options = {
        plugins: {
          legend: {
            display: true,
            labels: {
              // Ensure criteria / grade entry item labels are sorted in position order
              sort: (a, b) => {
                const itemA = this.props.summary.find(item => item.name === a.text);
                const itemB = this.props.summary.find(item => item.name === b.text);
                return itemA.position - itemB.position;
              },
            },
          },
        },
        scales: chartScales(),
      };
      return (
        <div className="flex-row">
          <div className="grade-breakdown-graph">
            <h3>{this.props.chart_title}</h3>
            <Bar
              data={this.props.distribution_data}
              options={graph_options}
              width="400"
              height="350"
            />
          </div>
          {summary_table}
        </div>
      );
    } else {
      return (
        <div className="grade-breakdown-graph">
          <h3>{this.props.chart_title}</h3>
          <h4>
            (
            <a href={this.props.create_link === undefined ? "" : this.props.create_link}>
              {I18n.t("helpers.submit.create", {
                model: this.props.item_name,
              })}
            </a>
            )
          </h4>
        </div>
      );
    }
  }
}

GradeBreakdownChart.propTypes = {
  show_stats: PropTypes.bool.isRequired,
  summary: PropTypes.array.isRequired,
  chart_title: PropTypes.string.isRequired,
  distribution_data: PropTypes.object,
  item_name: PropTypes.string.isRequired,
  num_groupings: PropTypes.number.isRequired,
  create_link: PropTypes.string,
};
