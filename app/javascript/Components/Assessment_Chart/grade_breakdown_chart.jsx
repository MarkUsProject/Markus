import React from "react";
import {Bar} from "react-chartjs-2";
import {chartScales} from "../Helpers/chart_helpers";
import Table from "../table/table";
import {createColumnHelper} from "@tanstack/react-table";
import PropTypes from "prop-types";
import {CoreStatistics} from "./core_statistics";
import {FractionStat} from "./fraction_stat";

const columnHelper = createColumnHelper();

export class GradeBreakdownChart extends React.Component {
  render() {
    const columns = [
      columnHelper.accessor("position", {
        id: "position",
        header: () => null,
        cell: () => null,
        size: 0,
        enableSorting: true,
        enableColumnFilter: false,
        meta: {
          className: "rt-hidden",
          headerClassName: "rt-hidden",
        },
      }),
      columnHelper.accessor("name", {
        header: this.props.item_name,
        minSize: 150,
        enableSorting: true,
        enableColumnFilter: false,
      }),
      columnHelper.accessor("average", {
        header: I18n.t("average"),
        enableSorting: false,
        enableColumnFilter: false,
        cell: info => (
          <FractionStat
            numerator={info.row.original.average}
            denominator={info.row.original.max_mark}
          />
        ),
      }),
    ];
    let summary_table = "";
    if (this.props.show_stats) {
      summary_table = (
        <div className="flex-row-expand">
          <div className="grade-breakdown-summary-table">
            <Table
              data={this.props.summary}
              columns={columns}
              initialState={{
                sorting: [{id: "position"}],
                columnVisibility: {position: false},
              }}
              getRowCanExpand={() => true}
              renderSubComponent={({row}) => (
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
