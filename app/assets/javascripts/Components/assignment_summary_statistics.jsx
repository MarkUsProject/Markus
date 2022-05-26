import React from "react";
import {render} from "react-dom";
import {Bar, Doughnut} from "react-chartjs-2";
import {chartScales} from "./Helpers/chart_helpers";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class AssignmentSummaryStatistics extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: null,
        median: null,
        num_submissions_collected: null,
        num_submissions_graded: null,
        num_fails: null,
        num_zeros: null,
        groupings_size: null,
      },
      assignment_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
        options: {
          scales: chartScales(),
        },
      },
      ta_grade_distribution: {
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
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.grade_distribution_course_assignment_path(
        this.props.course_id,
        this.props.assessment_id
      )
    )
      .then(data => data.json())
      .then(res => {
        // Load in background colours
        for (const [index, element] of res.ta_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }

        this.setState({
          summary: res.summary,
          assignment_grade_distribution: {
            ...this.state.assignment_grade_distribution,
            data: res.assignment_data,
          },
          ta_grade_distribution: {
            ...this.state.ta_grade_distribution,
            data: res.ta_data,
          },
        });
      });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }

  render() {
    return (
      <div className="assignment-data-display middle-align">
        <div className="assignment-statistics-summary">
          <div className="middle-align">
            <div className="inline-labels">
              <span>{I18n.t("average")}:</span>
              <span className="assignment-statistic-value">{this.state.summary.average}%</span>
            </div>
          </div>
          <div className="middle-align">
            <div className="inline-labels">
              <span>{I18n.t("median")}:</span>
              <span className="assignment-statistic-value">{this.state.summary.median}%</span>
            </div>
          </div>
          <RawAssignmentProgressStatistic
            label={I18n.t("num_failed")}
            progress={this.state.summary.num_fails}
            total={this.state.summary.groupings_size}
            higherIsWorse={true}
          />
          <RawAssignmentProgressStatistic
            label={I18n.t("num_zeros")}
            progress={this.state.summary.num_zeros}
            total={this.state.summary.groupings_size}
            higherIsWorse={true}
          />
          <RawAssignmentProgressStatistic
            label={I18n.t("assignments_submitted")}
            progress={this.state.summary.num_submissions_collected}
            total={this.state.summary.groupings_size}
          />
          <RawAssignmentProgressStatistic
            label={I18n.t("assignments_graded")}
            progress={this.state.summary.num_submissions_graded}
            total={this.state.summary.groupings_size}
          />
        </div>
        <div className="bar-graph">
          <h3>{I18n.t("assignment_distribution")}</h3>
          <Bar
            data={this.state.assignment_grade_distribution.data}
            options={this.state.assignment_grade_distribution.options}
          />
        </div>
        <div className="bar-graph">
          <h3>{I18n.t("grader_distribution")}</h3>
          <p className="float-right">
            <a
              href={Routes.grader_summary_course_assignment_graders_path(
                this.props.course_id,
                this.props.assessment_id
              )}
            >
              {I18n.t("activerecord.models.ta.other")}
            </a>
          </p>
          <Bar
            data={this.state.ta_grade_distribution.data}
            options={this.state.ta_grade_distribution.options}
          />
        </div>
      </div>
    );
  }
}

class RawAssignmentProgressStatistic extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      chart_data: {
        datasets: [
          {
            data: [],
            backgroundColor: [],
            borderColor: [],
          },
        ],
      },
    };
  }

  componentDidMount() {
    this.configChartData();
  }

  componentDidUpdate(prevProps) {
    if (prevProps.progress !== this.props.progress) {
      this.configChartData();
    }
  }

  // Helper to get hex value of CSS colour constants
  getHexColor = colorVar => document.documentElement.style.getPropertyValue(colorVar);

  // Updates the value and colour of the circular progress bar
  configChartData = () => {
    const percentage = Math.floor((this.props.progress / this.props.total || 0) * 100);
    let color;
    if (this.props.higherIsWorse && percentage > 0) {
      color = [this.getHexColor("--severe_error"), this.getHexColor("--light_error")];
    } else {
      color = [this.getHexColor("--primary_one"), this.getHexColor("--primary_two")];
    }
    this.setState({
      chart_data: {
        datasets: [
          {
            data: [percentage, 100 - percentage],
            backgroundColor: color,
            borderColor: color,
          },
        ],
      },
    });
  };

  render() {
    // Plugin for chart that inserts text in chart middle showing progress as a percentage of the total
    const textCenterPlugin = {
      beforeDraw: chart => {
        const ctx = chart.ctx;
        ctx.restore();
        ctx.font = "x-large Open Sans";
        ctx.textBaseline = "middle";
        const percentage = Math.floor((this.props.progress / this.props.total || 0) * 100);
        if (this.props.higherIsWorse && percentage > 0) {
          ctx.fillStyle = this.getHexColor("--severe_error");
        } else {
          ctx.fillStyle = this.getHexColor("--primary_one");
        }
        const textXCoord = Math.round((chart.width - ctx.measureText(`${percentage}%`).width) / 2);
        const textYCoord = Math.round(chart.height / 2);
        ctx.fillText(`${percentage}%`, textXCoord, textYCoord);
        ctx.save();
      },
    };

    return (
      <div className="middle-align">
        <div className="circular-progress-bar">
          <Doughnut
            data={this.state.chart_data}
            plugins={[textCenterPlugin]}
            options={{
              cutout: 42,
              events: [],
            }}
          />
        </div>
        <span>
          {this.props.label}: {this.props.progress} / {this.props.total}
        </span>
      </div>
    );
  }
}

class AssignmentSummary extends React.Component {
  render() {
    if (this.props.is_instructor) {
      return (
        <Tabs>
          <TabList>
            <Tab>{I18n.t("summary_statistics")}</Tab>
            <Tab>{I18n.t("summary_table")}</Tab>
          </TabList>
          <TabPanel>
            <AssignmentSummaryStatistics
              course_id={this.props.course_id}
              assessment_id={this.props.assessment_id}
            />
          </TabPanel>
          <TabPanel>
            <AssignmentSummaryTable
              course_id={this.props.course_id}
              assignment_id={this.props.assessment_id}
              is_instructor={this.props.is_instructor}
            />
          </TabPanel>
        </Tabs>
      );
    } else {
      return (
        <AssignmentSummaryTable
          course_id={this.props.course_id}
          assignment_id={this.props.assessment_id}
          is_instructor={this.props.is_instructor}
        />
      );
    }
  }
}

export function makeAssignmentSummary(elem, props) {
  return render(<AssignmentSummary {...props} />, elem);
}
