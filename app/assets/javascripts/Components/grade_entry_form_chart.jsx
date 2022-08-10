import React from "react";
import {AssessmentChart} from "./Assessment_Chart/assessment_chart";
import {GradeBreakdownChart} from "./Assessment_Chart/grade_breakdown_chart";
import {FractionStat} from "./Assessment_Chart/fraction_statistic";

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
      grade_entry_form_distribution: {
        data: {
          labels: [],
          datasets: [],
        },
      },
      column_summary: [],
      column_grade_distribution: {
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
        for (const [index, element] of res.column_breakdown_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }
        this.setState({
          summary: res.info_summary,
          column_summary: res.column_summary,
          grade_entry_form_distribution: {
            data: res.grade_dist_data,
          },
          column_grade_distribution: {
            data: res.column_breakdown_data,
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
      <React.Fragment>
        <h2>
          <a
            href={Routes.edit_course_grade_entry_form_path(
              this.props.course_id,
              this.props.assessment_id
            )}
          >
            {this.props.show_chart_header ? this.state.summary.name : ""}
          </a>
        </h2>
        <AssessmentChart
          summary={this.state.summary}
          assessment_data={this.state.grade_entry_form_distribution.data}
          additional_assessment_stats={
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
        />
        <GradeBreakdownChart
          show_table={this.props.show_column_table}
          summary={this.state.column_summary}
          chart_title={I18n.t("grade_entry_forms.grade_entry_item_distribution")}
          distribution_data={this.state.column_grade_distribution.data}
          item_name={I18n.t("activerecord.models.grade_entry_item.one")}
          assign_link={Routes.edit_course_grade_entry_form_path(
            this.props.course_id,
            this.props.assessment_id
          )}
        />
      </React.Fragment>
    );
  }
}
