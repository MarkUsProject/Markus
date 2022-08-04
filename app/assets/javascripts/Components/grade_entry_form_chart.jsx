import React from "react";
import {AssessmentChart, FractionStat} from "./assessment_chart";

export class GradeEntryFormChart extends React.Component {
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
      assessment_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
      },
      secondary_grade_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
      },
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.grade_distribution_course_grade_entry_form_path(
        this.props.course_id,
        this.props.assessment_id
      )
    )
      .then(data => data.json())
      .then(res => {
        this.setState({
          summary: res.summary,
          assessment_grade_distribution: {
            data: res.assessment_data,
          },
          secondary_grade_distribution: {
            data: res.secondary_assessment_data,
          },
        });
        for (const [index, element] of res.secondary_assessment_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }
      });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }

  render() {
    return (
      <AssessmentChart
        course_id={this.props.course_id}
        assessment_id={this.props.assessment_id}
        assessment_header_content={
          <a
            href={Routes.edit_course_grade_entry_form_path(
              this.props.course_id,
              this.props.assessment_id
            )}
          >
            {this.props.show_chart_header ? this.state.summary.name : ""}
          </a>
        }
        summary={this.state.summary}
        assessment_data={this.state.assessment_grade_distribution.data}
        additional_assessment_data={
          <React.Fragment>
            <span className="summary-stats-label">{I18n.t("attributes.date")}</span>
            <span>{this.state.summary.date}</span>
            <span className="summary-stats-label">{I18n.t("num_entries")}</span>
            <FractionStat
              numerator={this.state.summary.num_entries}
              denominator={this.state.summary.groupings_size}
            />
          </React.Fragment>
        }
        secondary_grade_distribution_title={I18n.t(
          "grade_entry_forms.grade_entry_item_distribution"
        )}
        secondary_grade_distribution_data={this.state.secondary_grade_distribution.data}
      />
    );
  }
}
