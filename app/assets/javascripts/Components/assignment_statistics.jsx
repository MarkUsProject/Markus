import React from "react";
import {render} from "react-dom";
import {Bar} from "react-chartjs-2";
import {chartScales} from "./Helpers/chart_helpers";

class AssignmentStatistics extends React.Component {
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
      <div>
        <div className="grid-2-col assignment-summary-data-dashboard">
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
        <div className="bar-graph-area">
          <div className="bar-graph">
            <Bar
              data={this.state.assignment_grade_distribution.data}
              options={this.state.assignment_grade_distribution.options}
            />
          </div>
        </div>
        {this.grader_distribution_graph()}
      </div>
    );
  }
}

class AssignmentSummaryValue extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      valu: 0,
    };
  }

  componentDidUpdate(prevState) {
    const num = (this.props.value || 0).toFixed(2);
    if (prevState.valu < num) {
      this.setState({
        value: prevState.valu + 1,
      });
    }
  }

  render() {
    return (
      <div>
        <span className="assignment-summary-text">{this.props.statistic}:</span>
        <span className="assignment-summary-value">{this.state.valu}%</span>
      </div>
    );
  }
}

class AssignmentSummaryPercentage extends React.Component {
  render() {
    return (
      <div>
        <div className="summary-progress-circle">
          {(this.props.progress / this.props.total || 0).toFixed(2) * 100}%
        </div>
        <span>
          {this.props.statisticText}: {this.props.progress} / {this.props.total}
        </span>
      </div>
    );
  }
}

export function makeAssignmentStatistics(elem, props) {
  return render(<AssignmentStatistics {...props} />, elem);
}
