import {createRoot} from "react-dom/client";
import {AssignmentSummaryTable} from "./assignment_summary_table";
import {AssignmentChart} from "./assignment_chart";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

function AssignmentSummary({
  assessment_id,
  can_view_assigned_submissions_only,
  course_id,
  encodings,
  initial_show_assigned_submissions_only,
  is_instructor,
  lti_deployments,
}) {
  if (is_instructor) {
    return (
      <Tabs>
        <TabList>
          <Tab>{I18n.t("summary_table")}</Tab>
          <Tab>{I18n.t("summary_statistics")}</Tab>
        </TabList>
        <TabPanel>
          <AssignmentSummaryTable
            course_id={course_id}
            assignment_id={assessment_id}
            is_instructor={is_instructor}
            encodings={encodings}
            lti_deployments={lti_deployments}
            can_view_assigned_submissions_only={can_view_assigned_submissions_only}
            initial_show_assigned_submissions_only={initial_show_assigned_submissions_only}
          />
        </TabPanel>
        <TabPanel>
          <div className="expanded-summary-stats">
            <AssignmentChart
              course_id={course_id}
              assessment_id={assessment_id}
              show_criteria_stats={true}
            />
          </div>
        </TabPanel>
      </Tabs>
    );
  }

  return (
    <AssignmentSummaryTable
      course_id={course_id}
      assignment_id={assessment_id}
      is_instructor={is_instructor}
      encodings={encodings}
      lti_deployments={lti_deployments}
      can_view_assigned_submissions_only={can_view_assigned_submissions_only}
      initial_show_assigned_submissions_only={initial_show_assigned_submissions_only}
    />
  );
}

export function makeAssignmentSummary(elem, props) {
  const root = createRoot(elem);
  return root.render(<AssignmentSummary {...props} />);
}
