import React from "react";
import {render} from "react-dom";
import {CourseSummaryChart} from "./course_summary_chart";
import {AssignmentChart} from "./assignment_chart";
import {GradeEntryFormChart} from "./grade_entry_form_chart";

class Dashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assessment_id: null,
      assessment_type: null,
      display_course_summary: false,
    };
  }

  render() {
    if (this.state.display_course_summary) {
      return <CourseSummaryChart course_id={this.props.course_id} />;
    } else if (this.state.assessment_type === "Assignment") {
      return (
        <AssignmentChart
          course_id={this.props.course_id}
          assessment_id={this.state.assessment_id}
        />
      );
    } else if (this.state.assessment_type === "GradeEntryForm") {
      return (
        <GradeEntryFormChart
          course_id={this.props.course_id}
          assessment_id={this.state.assessment_id}
        />
      );
    } else {
      return "";
    }
  }
}

export function makeDashboard(elem, props) {
  return render(<Dashboard {...props} />, elem);
}
