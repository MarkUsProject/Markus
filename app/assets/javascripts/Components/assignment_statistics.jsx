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

  render() {
    const grader_distribution_graph = (
      <div>
        <h3>{I18n.t("grader_distribution")}</h3>
        <Bar
          data={this.state.ta_grade_distribution.data}
          options={this.state.ta_grade_distribution.options}
          width="400"
          height="350"
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

    return (
      <div>
        <Bar
          data={this.state.assignment_grade_distribution.data}
          options={this.state.assignment_grade_distribution.options}
          width="500"
          height="450"
        />
        {this.state.ta_grade_distribution.data.datasets.length !== 0
          ? grader_distribution_graph
          : ""}
      </div>
    );
  }
}

class AssignmentStatisticsValue extends React.Component {
  render() {
    return (
      <div>
        <p>{this.props.statistic}:</p>
        <p className={"assignment-stat-value"}>{this.props.value}</p>
      </div>
    );
  }
}

export function makeAssignmentStatistics(elem, props) {
  return render(<AssignmentStatistics {...props} />, elem);
}
