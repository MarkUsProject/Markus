import React from "react";
import {render} from "react-dom";
import {GradeEntryFormChart} from "./grade_entry_form_chart";
import {MarksSpreadsheet} from "./marks_spreadsheet";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

class GradeEntryFormSummary extends React.Component {
  render() {
    if (this.props.can_manage) {
      return (
        <Tabs>
          <TabList>
            <Tab>{I18n.t("activerecord.attributes.grade_entry_form.grades")}</Tab>
            <Tab>{I18n.t("summary_statistics")}</Tab>
          </TabList>
          <TabPanel>
            <MarksSpreadsheet
              course_id={this.props.course_id}
              grade_entry_form_id={this.props.grade_entry_form_id}
              show_total={this.props.show_total}
              max_mark={this.props.max_mark}
              show_sections={this.props.show_sections}
              can_release={this.props.can_manage}
            />
          </TabPanel>
          <TabPanel>
            <div className="expanded-summary-stats">
              <GradeEntryFormChart
                course_id={this.props.course_id}
                assessment_id={this.props.grade_entry_form_id}
                show_column_table={true}
              />
            </div>
          </TabPanel>
        </Tabs>
      );
    } else {
      return (
        <MarksSpreadsheet
          course_id={this.props.course_id}
          grade_entry_form_id={this.props.grade_entry_form_id}
          show_total={this.props.show_total}
          max_mark={this.props.max_mark}
          show_sections={this.props.show_sections}
          can_release={this.props.can_manage}
        />
      );
    }
  }
}

export function makeGradeEntryFormSummary(elem, props) {
  return render(<GradeEntryFormSummary {...props} />, elem);
}
