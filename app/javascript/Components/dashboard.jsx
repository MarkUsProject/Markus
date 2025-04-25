import React from "react";
import {createRoot} from "react-dom/client";
import {AssignmentChart} from "./assignment_chart";
import {GradeEntryFormChart} from "./grade_entry_form_chart";
import {CourseSummaryChart} from "./course_summary_chart";

class Dashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assessment_id: props.initial_assessment_id || null,
      assessment_type: props.initial_assessment_type || null,
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
          show_chart_header={true}
        />
      );
    } else if (this.state.assessment_type === "GradeEntryForm") {
      return (
        <GradeEntryFormChart
          course_id={this.props.course_id}
          assessment_id={this.state.assessment_id}
          show_chart_header={true}
          show_column_stats={false}
        />
      );
    } else {
      return "";
    }
  }
}

export function makeDashboard(elem, props) {
  const root = createRoot(elem);
  const component = React.createRef();
  root.render(<Dashboard {...props} ref={component} />);
  return component;
}
