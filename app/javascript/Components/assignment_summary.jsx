import React from "react";
import {createRoot} from "react-dom/client";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {AssignmentChart} from "./assignment_chart";
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
              lti_deployments={this.props.lti_deployments}
            />
          </TabPanel>
          <TabPanel>
            <div className="expanded-summary-stats">
              <AssignmentChart
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
          lti_deployments={this.props.lti_deployments}
        />
      );
    }
  }
}

export function makeAssignmentSummary(elem, props) {
  const root = createRoot(elem);
  return root.render(<AssignmentSummary {...props} />);
}
