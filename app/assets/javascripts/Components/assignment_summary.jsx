import React from "react";
import {render} from "react-dom";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {AssessmentChart} from "./assessment_chart";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class AssignmentSummary extends React.Component {
  render() {
    if (this.props.is_instructor) {
      return (
        <Tabs>
          <TabList>
            <Tab>{I18n.t("summary_table")}</Tab>
            <Tab>{I18n.t("summary_statistics")}</Tab>
          </TabList>
          <TabPanel>
            <AssignmentSummaryTable
              course_id={this.props.course_id}
              assignment_id={this.props.assessment_id}
              is_instructor={this.props.is_instructor}
            />
          </TabPanel>
          <TabPanel>
            <div className="expanded-summary-stats">
              <AssessmentChart
                course_id={this.props.course_id}
                assessment_id={this.props.assessment_id}
                show_criteria_stats={true}
              />
            </div>
          </TabPanel>
        </Tabs>
      );
    } else {
      return (
        <AssignmentSummaryTable
          course_id={this.props.course_id}
          assignment_id={this.props.assessment_id}
          is_instructor={this.props.is_instructor}
        />
      );
    }
  }
}

export function makeAssignmentSummary(elem, props) {
  return render(<AssignmentSummary {...props} />, elem);
}
