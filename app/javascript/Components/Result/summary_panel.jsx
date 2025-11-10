import React from "react";
import ReactTable from "react-table";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";
import {DataChart} from "../Helpers/data_chart";
import {ResultContext} from "./result_context";

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
    };
  }

  componentDidMount() {
    this.marks_modal = new ModalMarkus("#marks_chart");
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
      });
    } else {
      this.setState({
        datasets: [this.markDataSet],
        labels: labels,
        chartLegend: false,
      });
    }
    this.marks_modal.open();
  };

  criterionColumns = () => [
    {
      Header: I18n.t("activerecord.models.criterion.one"),
      accessor: "criterion",
      classes: ["left"],
    },
    {
      Header: "Old Mark",
      accessor: "old_mark.mark",
      className: "number",
      show: this.props.remark_submitted,
    },
    {
      Header: I18n.t("activerecord.models.mark.one"),
      id: "mark",
      className: "number",
      Cell: row => {
        let mark = row.original.mark;
        if (mark === undefined || mark === null) {
          mark = "-";
        }
        return `${mark} / ${row.original.max_mark}`;
      },
    },
  ];

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

  extraMarksColumns = () => [
    {
      Header: I18n.t("activerecord.attributes.extra_mark.description"),
      accessor: "description",
      minWidth: 150,
      Cell: row => {
        if (row.original._new) {
          return <input type={"text"} defaultValue="" style={{width: "100%"}} />;
        } else {
          return row.value;
        }
      },
    },
    {
      Header: I18n.t("activerecord.attributes.extra_mark.extra_mark"),
      accessor: "extra_mark",
      minWidth: 80,
      className: "number",
      Cell: row => {
        if (row.original._new) {
          return <input type={"number"} step="any" defaultValue={0} />;
        } else if (row.original.unit === "points") {
          return row.value;
        } else if (row.original.unit === "percentage_of_mark") {
          let mark_value = ((row.value * this.props.subtotal) / 100).toFixed(2);
          return `${mark_value} (${row.value}%)`;
        } else {
          // Percentage
          let mark_value = ((row.value * this.props.assignment_max_mark) / 100).toFixed(2);
          return `${mark_value} (${row.value}%)`;
        }
      },
    },
    {
      Header: "",
      id: "action",
      show: !this.props.released_to_students,
      Cell: row => {
        if (row.original._new) {
          return (
            <button onClick={this.createExtraMark} className="inline-button">
              {I18n.t("save")}
            </button>
          );
        } else {
          return (
            <button
              onClick={() => this.props.destroyExtraMark(row.original.id)}
              className="inline-button"
            >
              {I18n.t("delete")}
            </button>
          );
        }
      },
    },
  ];

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
        {data.length > 0 && <ReactTable columns={this.extraMarksColumns()} data={data} />}
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
        <aside className="markus-dialog data-chart-container" id={"marks_chart"} style={style}>
          <DataChart
            labels={this.state.labels}
            datasets={this.state.datasets}
            xTitle={this.state.xTitle}
            yTitle={this.state.yTitle}
            legend={this.state.chartLegend}
          />
        </aside>
        <ReactTable
          columns={this.criterionColumns()}
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
