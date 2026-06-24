import React from "react";
import Modal from "react-modal";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {Bar} from "react-chartjs-2";
import {chartScales} from "../Helpers/chart_helpers";
import {ResultContext} from "./result_context";
import {createColumnHelper} from "@tanstack/react-table";
import Table from "../table/table";

export class SummaryPanel extends React.Component {
  static contextType = ResultContext;

  static defaultProps = {
    criterionSummaryData: [],
    extra_marks: [],
    extraMarkSubtotal: 0,
    graceTokenDeductions: [],
  };

  markDataSet = {
    label: I18n.t("activerecord.models.mark.one"),
    backgroundColor: "rgba(58,106,179,0.35)",
    border: {color: "#3a6ab3", width: 1},
    hoverBackgroundColor: "rgba(58,106,179,0.75)",
  };

  // Colors for chart are based on constants.css file, with modifications for opacity.
  oldMarkDataSet = {
    label: I18n.t("results.remark.old_mark"),
    backgroundColor: "rgba(250,253,170,0.65)",
    border: {color: "#dde426", width: 1},
    hoverBackgroundColor: "#dde426",
  };

  constructor(props) {
    super(props);
    this.state = {
      showNewExtraMark: false,
      xTitle: I18n.t("activerecord.models.criterion.one"),
      yTitle: I18n.t("activerecord.models.mark.one") + " (%)",
      datasets: [],
      labels: [],
      chartLegend: false,
      showMarksChart: false,
      criterionColumns: this.criterionColumns(props.remark_submitted),
      extraMarksColumns: this.extraMarksColumns(props.released_to_students),
    };
  }

  componentDidUpdate(prevProps) {
    if (prevProps.remark_submitted !== this.props.remark_submitted) {
      this.setState({criterionColumns: this.criterionColumns(this.props.remark_submitted)});
    }
    if (prevProps.released_to_students !== this.props.released_to_students) {
      this.setState({extraMarksColumns: this.extraMarksColumns(this.props.released_to_students)});
    }
  }

  componentDidMount() {
    Modal.setAppElement("body");
  }

  toggleMarksChart = () => {
    let labels = [];
    let markData = [];
    let oldMarks = [];
    let oldMarksExist = Object.keys(this.props.old_marks).length > 0;
    this.props.marks.forEach(m => {
      labels.push(m.name);
      markData.push(Math.round(m.mark * 100) / m.max_mark);
      if (oldMarksExist) {
        oldMarks.push(Math.round(this.props.old_marks[m.id] * 100) / m.max_mark);
      }
    });
    this.markDataSet.data = markData;
    if (oldMarksExist) {
      this.oldMarkDataSet.data = oldMarks;
      this.markDataSet.label = I18n.t("results.current_mark");
      this.setState({
        datasets: [this.oldMarkDataSet, this.markDataSet],
        labels: labels,
        chartLegend: true,
        showMarksChart: true,
      });
    } else {
      this.setState({
        datasets: [this.markDataSet],
        labels: labels,
        chartLegend: false,
        showMarksChart: true,
      });
    }
  };

  closeMarksChart = () => {
    this.setState({showMarksChart: false});
  };

  columnHelper = createColumnHelper();

  criterionColumns = remark_submitted => {
    let columns = [
      this.columnHelper.accessor("criterion", {
        header: I18n.t("activerecord.models.criterion.one"),
        meta: {
          className: "left",
        },
        enableColumnFilter: false,
      }),
    ];

    if (remark_submitted) {
      columns.push(
        this.columnHelper.accessor("old_mark.mark", {
          header: I18n.t("activerecord.models.mark.old"),
          meta: {
            className: "number",
          },
          enableColumnFilter: false,
        })
      );
    }

    columns.push(
      this.columnHelper.display({
        header: I18n.t("activerecord.models.mark.one"),
        id: "mark",
        meta: {
          className: "number",
        },
        cell: props => {
          let mark = props.row.original.mark;
          if (mark === undefined || mark === null) {
            mark = "-";
          }
          return `${mark} / ${props.row.original.max_mark}`;
        },
        enableColumnFilter: false,
      })
    );

    return columns;
  };

  renderTotalMark = () => {
    const assignment_total = Math.round(this.props.assignment_max_mark * 100) / 100;
    let oldTotal = "";
    if (this.props.remark_submitted) {
      oldTotal = (
        <div className="highlight-bar">
          <span>{I18n.t("results.remark.old_total")}</span>
          <span className="float-right">
            <span>{this.props.old_total}</span>
            &nbsp;/&nbsp;
            {assignment_total}
          </span>
        </div>
      );
    }
    let currentTotal = (
      <div className="highlight-bar">
        <span>{I18n.t("results.total_mark")}</span>
        <span className="float-right">
          <span>{this.props.total}</span>
          &nbsp;/&nbsp;
          {assignment_total}
        </span>
      </div>
    );

    return (
      <div>
        {oldTotal}
        {currentTotal}
      </div>
    );
  };

  extraMarksColumns = released_to_students => {
    let columns = [
      this.columnHelper.accessor("description", {
        header: I18n.t("activerecord.attributes.extra_mark.description"),
        minSize: 150,
        cell: props => {
          if (props.row.original._new) {
            return <input type={"text"} defaultValue="" style={{width: "100%"}} />;
          } else {
            return props.getValue();
          }
        },
        enableColumnFilter: false,
      }),
      this.columnHelper.accessor("extra_mark", {
        header: I18n.t("activerecord.attributes.extra_mark.extra_mark"),
        minSize: 80,
        meta: {
          className: "number",
        },
        cell: props => {
          if (props.row.original._new) {
            return <input type={"number"} step="any" defaultValue={0} />;
          } else if (props.row.original.unit === "points") {
            return props.getValue();
          } else if (props.row.original.unit === "percentage_of_mark") {
            let mark_value = ((props.getValue() * this.props.subtotal) / 100).toFixed(2);
            return `${mark_value} (${props.getValue()}%)`;
          } else {
            // Percentage
            let mark_value = ((props.getValue() * this.props.assignment_max_mark) / 100).toFixed(2);
            return `${mark_value} (${props.getValue()}%)`;
          }
        },
        enableColumnFilter: false,
      }),
    ];

    if (!released_to_students) {
      columns.push(
        this.columnHelper.display({
          header: "",
          id: "action",
          cell: props => {
            if (props.row.original._new) {
              return (
                <button onClick={this.createExtraMark} className="inline-button">
                  {I18n.t("save")}
                </button>
              );
            } else {
              return (
                <button
                  onClick={() => this.props.destroyExtraMark(props.row.original.id)}
                  className="inline-button"
                >
                  {I18n.t("delete")}
                </button>
              );
            }
          },
          enableColumnFilter: false,
        })
      );
    }

    return columns;
  };

  newExtraMark = () => {
    this.setState({showNewExtraMark: true});
  };

  createExtraMark = event => {
    let row = event.target.parentElement.parentElement;
    let description = row.children[0].children[0].value;
    let extra_mark = row.children[1].children[0].value;
    this.props
      .createExtraMark(description, extra_mark)
      .then(() => this.setState({showNewExtraMark: false}));
  };

  renderExtraMarks = () => {
    // If there are no extra marks and this result is released, display nothing.
    if (
      this.context.is_reviewer ||
      (this.props.released_to_students && this.props.extra_marks.length === 0)
    ) {
      return "";
    }

    let data;
    if (this.state.showNewExtraMark) {
      data = this.props.extra_marks.concat([
        {
          _new: true,
          extra_mark: 0,
          description: "",
          id: null,
        },
      ]);
    } else {
      data = this.props.extra_marks;
    }

    return (
      <div>
        <h4>{I18n.t("activerecord.models.extra_mark.other")}</h4>
        {data.length > 0 && <Table columns={this.state.extraMarksColumns} data={data} />}
        {!this.props.released_to_students && (
          <p>
            <button className="inline-button" onClick={this.newExtraMark}>
              {I18n.t("helpers.submit.create", {
                model: I18n.t("activerecord.models.extra_mark.one"),
              })}
            </button>
          </p>
        )}
        <div className="highlight-bar">
          {I18n.t("results.total_extra_marks")}
          <span className="float-right">{this.props.extraMarkSubtotal.toFixed(2)}</span>
        </div>
      </div>
    );
  };

  renderGraceTokenDeductions = () => {
    if (this.context.is_reviewer || this.props.graceTokenDeductions.length === 0) {
      return "";
    } else {
      let rows = this.props.graceTokenDeductions.flatMap(d => {
        return [
          <tr key={d["users.user_name"]}>
            <th colSpan={2}>{`${d["users.user_name"]} - (${d["users.display_name"]})`}</th>
          </tr>,
          <tr key={d["users.user_name"] + "-deduction"}>
            <td>
              {I18n.t("grace_period_submission_rules.credit", {
                count: d.deduction,
              })}
            </td>
            <td>
              {!this.props.released_to_students && (
                <button
                  className="inline-button"
                  onClick={() => this.props.deleteGraceTokenDeduction(d.id)}
                >
                  {I18n.t("delete")}
                </button>
              )}
            </td>
          </tr>,
        ];
      });

      return (
        <div>
          <h3>{I18n.t("activerecord.models.grace_period_deduction.other")}</h3>
          <table>
            <tbody>{rows}</tbody>
          </table>
        </div>
      );
    }
  };

  render() {
    const style = {
      width: window.innerWidth * 0.75 + "px",
      height: window.innerHeight * 0.6 + "px",
    };
    return (
      <div>
        <p style={{textAlign: "center"}}>
          <button onClick={() => this.toggleMarksChart()} style={{width: "85%"}}>
            <FontAwesomeIcon icon="fa-solid fa-chart-column" />
            {I18n.t("results.marks_chart")}
          </button>
        </p>
        <Modal
          className="react-modal markus-dialog data-chart-container"
          id={"marks_chart"}
          isOpen={this.state.showMarksChart}
          onRequestClose={this.closeMarksChart}
          style={{content: style}}
        >
          <Bar
            data={{labels: this.state.labels, datasets: this.state.datasets}}
            options={{
              responsive: true,
              maintainAspectRatio: false,
              plugins: {legend: {display: this.state.chartLegend}},
              scales: chartScales(this.state.xTitle, this.state.yTitle),
            }}
            height={500}
          />
        </Modal>
        <Table
          columns={this.state.criterionColumns}
          data={this.props.criterionSummaryData}
          className="auto-overflow"
        />
        <div className="highlight-bar">
          {I18n.t("results.subtotal")}
          <span className="float-right">
            {this.props.subtotal}
            &nbsp;/&nbsp;
            {+this.props.assignment_max_mark}
          </span>
        </div>
        {this.renderGraceTokenDeductions()}
        {this.renderExtraMarks()}
        {this.renderTotalMark()}
      </div>
    );
  }
}
