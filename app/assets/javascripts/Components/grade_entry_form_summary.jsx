import React from "react";
import {render} from "react-dom";
import {GradeEntryFormChart} from "./grade_entry_form_chart";

class GradeEntryFormSummary extends React.Component {
  render() {
    return (
      <div className="expanded-summary-stats">
        <GradeEntryFormChart
          course_id={this.props.course_id}
          assessment_id={this.props.assessment_id}
        />
      </div>
    );
  }
}

export function makeGradeEntryFormSummary(elem, props) {
  return render(<GradeEntryFormSummary {...props} />, elem);
}
