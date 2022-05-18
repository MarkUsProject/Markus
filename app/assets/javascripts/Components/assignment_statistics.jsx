import React from "react";
import {render} from "react-dom";
import {Bar} from "react-chartjs-2";
import {chartScales} from "./Helpers/chart_helpers";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class AssignmentDataDisplay extends React.Component {
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
    const {
      average,
      median,
      num_fails,
      num_zeros,
      num_submissions_collected,
      num_submissions_graded,
      groupings_size,
    } = this.state.summary;
    return (
      <div className="assignment-statistics-display">
        <div className="aaa">
          <div className="ccc">
            <div className="inline-labels">
              <span>{I18n.t("average")}:</span>
              <span className="assignment-summary-value">{average}%</span>
            </div>
            <RawAssignmentProgressStatistic
              label={I18n.t("num_failed")}
              progress={num_fails}
              total={groupings_size}
            />
            <RawAssignmentProgressStatistic
              label={I18n.t("assignments_submitted")}
              progress={num_submissions_collected}
              total={groupings_size}
            />
          </div>
          <div className="ccc">
            <div className="inline-labels">
              <span>{I18n.t("median")}:</span>
              <span className="assignment-summary-value">{median}%</span>
            </div>
            <RawAssignmentProgressStatistic
              label={I18n.t("num_zeros")}
              progress={num_zeros}
              total={groupings_size}
            />
            <RawAssignmentProgressStatistic
              label={I18n.t("assignments_graded")}
              progress={num_submissions_graded}
              total={groupings_size}
            />
          </div>
        </div>
        <div className="bar-graph">
          <h3>{"Assignment Grade Distribution"}</h3>
          <Bar
            data={this.state.assignment_grade_distribution.data}
            options={this.state.assignment_grade_distribution.options}
          />
        </div>
        <div className="bar-graph">
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
      </div>
    );
  }
}

class RawAssignmentProgressStatistic extends React.Component {
  render() {
    const {progress, total, label, higherIsWorse} = this.props;
    const percentage = Math.floor((progress / total || 0) * 100);
    const progressClass =
      higherIsWorse && progress > 0 ? "circular-progress-bar-bad" : "circular-progress-bar-normal";
    return (
      <div className="assignment-percentage-statistic">
        <div className={`circular-container ${progressClass}`} style={{"--value": percentage}}>
          <div className="circular-container circular-progress-bar-inner-display">
            {percentage}%
          </div>
        </div>
        <span>
          {label}: {progress} / {total}
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
          <AssignmentDataDisplay
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
