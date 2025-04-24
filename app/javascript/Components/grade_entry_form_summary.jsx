import React from "react";
import {createRoot} from "react-dom/client";
import {GradeEntryFormChart} from "./grade_entry_form_chart";
import {MarksSpreadsheet} from "./marks_spreadsheet";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class GradeEntryFormSummary extends React.Component {
  render() {
    const marks_spreadsheet = (
      <MarksSpreadsheet
        course_id={this.props.course_id}
        grade_entry_form_id={this.props.grade_entry_form_id}
        show_total={this.props.show_total}
        max_mark={this.props.max_mark}
        show_sections={this.props.show_sections}
        can_release={this.props.can_manage}
      />
    );
    if (this.props.can_manage) {
      return (
        <Tabs>
          <TabList>
            <Tab>{I18n.t("activerecord.attributes.grade_entry_form.grades")}</Tab>
            <Tab>{I18n.t("summary_statistics")}</Tab>
          </TabList>
          <TabPanel forceRender={true}>{marks_spreadsheet}</TabPanel>
          <TabPanel>
            <div className="expanded-summary-stats">
              <GradeEntryFormChart
                course_id={this.props.course_id}
                assessment_id={this.props.grade_entry_form_id}
                show_column_stats={true}
              />
            </div>
          </TabPanel>
        </Tabs>
      );
    } else {
      return marks_spreadsheet;
    }
  }
}

export function makeGradeEntryFormSummary(elem, props) {
  const root = createRoot(elem);
  return root.render(<GradeEntryFormSummary {...props} />);
}
