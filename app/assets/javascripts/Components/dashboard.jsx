import React from "react";
import {render} from "react-dom";
import {AssignmentChart} from "./assignment_chart";
import {GradeEntryFormChart} from "./grade_entry_form_chart";
import {CourseSummaryChart} from "./course_summary_chart";

class Dashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assessment_id: null,
      assessment_name: null,
      assessment_type: null,
      display_course_summary: false,
    };
  }

  setAssessmentName = name => this.setState({assessment_name: name});

  renderAssessmentChart = headerPath => {
    return (
      <React.Fragment>
        <h2>
          <a href={headerPath(this.props.course_id, this.state.assessment_id)}>
            {this.state.assessment_name}
          </a>
        </h2>
        <AssignmentChart
          course_id={this.props.course_id}
          assessment_id={this.state.assessment_id}
          set_assessment_name={this.setAssessmentName}
          assessment_type={this.state.assessment_type}
        />
      </React.Fragment>
    );
  };

  render() {
    if (this.state.display_course_summary) {
      return <CourseSummaryChart course_id={this.props.course_id} />;
    } else if (this.state.assessment_type === "Assignment") {
      return this.renderAssessmentChart(Routes.browse_course_assignment_submissions_path);
    } else if (this.state.assessment_type === "GradeEntryForm") {
      return this.renderAssessmentChart(Routes.edit_course_grade_entry_form_path);
    } else {
      return "";
    }
  }
}

export function makeDashboard(elem, props) {
  return render(<Dashboard {...props} />, elem);
}
