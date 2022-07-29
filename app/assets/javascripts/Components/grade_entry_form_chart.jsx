import React from "react";
import {AssessmentChart, FractionStat} from "./assessment_chart";

export class GradeEntryFormChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: [],
    };
  }

  render() {
    const fetch_data = setAssessmentState => {
      fetch(
        Routes.grade_distribution_course_grade_entry_form_path(
          this.props.course_id,
          this.props.assessment_id
        )
      )
        .then(data => data.json())
        .then(res => {
          setAssessmentState(res.summary, res.assessment_data, res.column_breakdown_data);
          this.setState({summary: res.summary});
        });
    };

    const additional_assessment_data = (
      <React.Fragment>
        <span className="summary-stats-label">{I18n.t("attributes.date")}</span>
        <span>{this.state.summary.date}</span>
        <span className="summary-stats-label">{I18n.t("num_entries")}</span>
        <FractionStat
          numerator={this.state.summary.num_entries}
          denominator={this.state.summary.groupings_size}
        />
      </React.Fragment>
    );

    const assessment_header_content = (
      <a
        href={Routes.edit_course_grade_entry_form_path(
          this.props.course_id,
          this.props.assessment_id
        )}
      >
        {this.state.summary.name}
      </a>
    );

    return (
      <AssessmentChart
        assessment_header_content={assessment_header_content}
        fetch_data={fetch_data}
        secondary_grade_distribution_title={I18n.t(
          "grade_entry_forms.grade_entry_item_distribution"
        )}
        additional_assessment_data={additional_assessment_data}
        course_id={this.props.course_id}
        assessment_id={this.props.assessment_id}
      />
    );
  }
}
