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
    return (
      <AssessmentChart
        course_id={this.props.course_id}
        assessment_id={this.props.assessment_id}
        fetch_url={Routes.grade_distribution_course_grade_entry_form_path(
          this.props.course_id,
          this.props.assessment_id
        )}
        set_chart_type_state={res => this.setState({summary: res.summary})}
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
      />
    );
  }
}
