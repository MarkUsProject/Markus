import React from 'react';
import { render } from 'react-dom';
import { AssignmentChart } from './assignment_chart'
import { GradeEntryChart } from './grade_entry_form_chart'
import { CourseSummaryChart} from "./course_summary_chart";

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
      return <CourseSummaryChart />;
    } else if (this.state.assessment_type === 'Assignment') {
      return <AssignmentChart assessment_id={this.state.assessment_id}/>;
    } else if (this.state.assessment_type === 'GradeEntryForm') {
      return <GradeEntryChart assessment_id={this.state.assessment_id} />;
    } else {
      return '';
    }
  }
}


export function makeDashboard(elem) {
  return render(<Dashboard />, elem);
}
