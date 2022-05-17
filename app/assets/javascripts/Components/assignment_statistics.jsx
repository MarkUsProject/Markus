import React from "react";
import {render} from "react-dom";
import {Bar} from "react-chartjs-2";
import {chartScales} from "./Helpers/chart_helpers";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class AssignmentStatisticsDisplay extends React.Component {
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

  grader_distribution_graph = () => {
    if (this.state.ta_grade_distribution.data.datasets.length !== 0) {
      return (
        <div>
          <h3>{I18n.t("grader_distribution")}</h3>
          <Bar
            data={this.state.ta_grade_distribution.data}
            options={this.state.ta_grade_distribution.options}
          />
          <p>
            <a
              href={Routes.grader_summary_course_assignment_graders_path(
                this.props.course_id,
                this.props.assessment_id
              )}
            >
              {I18n.t("activerecord.models.ta.other")}
            </a>
          </p>
        </div>
      );
    }
  };

  render() {
    return (
      <div className="assignment-statistics-display">
        <div className="grid-2-col">
          <AssignmentSummaryValue
            statistic={I18n.t("average")}
            value={this.state.summary.average}
          />
          <AssignmentSummaryValue statistic={I18n.t("median")} value={this.state.summary.median} />
          <AssignmentSummaryValue
            statistic={I18n.t("num_failed")}
            value={this.state.summary.num_fails}
          />
          <AssignmentSummaryValue
            statistic={I18n.t("num_zeros")}
            value={this.state.summary.num_zeros}
          />
          <AssignmentSummaryPercentage
            statisticText={I18n.t("assignments_submitted")}
            progress={this.state.summary.num_submissions_collected}
            total={this.state.summary.groupings_size}
          />
          <AssignmentSummaryPercentage
            statisticText={I18n.t("assignments_graded")}
            progress={this.state.summary.num_submissions_graded}
            total={this.state.summary.groupings_size}
          />
        </div>
        <div className="bar-graph">
          <Bar
            data={this.state.assignment_grade_distribution.data}
            options={this.state.assignment_grade_distribution.options}
          />
        </div>
        {this.grader_distribution_graph()}
      </div>
    );
  }
}

class AssignmentSummaryValue extends React.Component {
  render() {
    return (
      <div>
        <span className="assignment-summary-text">{this.props.statistic}:</span>
        <span className="assignment-summary-value">{(this.props.value || 0).toFixed(2)}%</span>
      </div>
    );
  }
}

class AssignmentSummaryPercentage extends React.Component {
  render() {
    const percentage = Math.floor((this.props.progress / this.props.total || 0) * 100);
    return (
      <div>
        <div className="circular-progress-bar" style={{"--value": percentage}}>
          <div className="circular-progress-bar-display">{percentage}%</div>
        </div>
        <span>
          {this.props.statisticText}: {this.props.progress} / {this.props.total}
        </span>
      </div>
    );
  }
}

class AssignmentStatistics extends React.Component {
  render() {
    return (
      <Tabs>
        <TabList>
          <Tab>{"Statistics Display"}</Tab>
          <Tab>{"Summary Table"}</Tab>
        </TabList>
        <TabPanel>
          <AssignmentStatisticsDisplay
            course_id={this.props.course_id}
            assessment_id={this.props.assessment_id}
          />
        </TabPanel>
        <TabPanel>
          <AssignmentSummaryTable
            course_id={this.props.course_id}
            assignment_id={this.props.assessment_id}
            is_instructor={true}
          />
        </TabPanel>
      </Tabs>
    );
  }
}

export function makeAssignmentStatistics(elem, props) {
  return render(<AssignmentStatistics {...props} />, elem);
}
