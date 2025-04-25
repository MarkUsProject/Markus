import React from "react";
import {Tab, Tabs, TabList, TabPanel} from "react-tabs";

import {MarksPanel} from "./marks_panel";
import {SummaryPanel} from "./summary_panel";
import {SubmissionInfoPanel} from "./submission_info_panel";
import {ResultContext} from "./result_context";

export class RightPane extends React.Component {
  static contextType = ResultContext;

  canShowSubmissionInfoPanel = () => {
    return this.context.role !== "Student" && !this.context.is_reviewer;
  };

  render() {
    return (
      <Tabs>
        <TabList>
          <Tab>{I18n.t("activerecord.models.mark.other")}</Tab>
          <Tab>{I18n.t("results.summary")}</Tab>
          {this.canShowSubmissionInfoPanel() && <Tab>{I18n.t("results.submission_info")}</Tab>}
        </TabList>
        <TabPanel>
          <MarksPanel
            annotations={this.props.annotations}
            old_marks={this.props.old_marks}
            marks={this.props.marks}
            assigned_criteria={this.props.assigned_criteria}
            released_to_students={this.props.released_to_students}
            updateMark={this.props.updateMark}
            destroyMark={this.props.destroyMark}
            revertToAutomaticDeductions={this.props.revertToAutomaticDeductions}
            findDeductiveAnnotation={this.props.findDeductiveAnnotation}
          />
        </TabPanel>
        <TabPanel>
          <SummaryPanel
            old_marks={this.props.old_marks}
            marks={this.props.marks}
            released_to_students={this.props.released_to_students}
            remark_submitted={this.props.remark_submitted}
            assignment_max_mark={this.props.assignment_max_mark}
            old_total={this.props.old_total}
            total={this.props.total}
            subtotal={this.props.subtotal}
            extraMarkSubtotal={this.props.extraMarkSubtotal}
            extra_marks={this.props.extra_marks}
            criterionSummaryData={this.props.criterionSummaryData}
            graceTokenDeductions={this.props.grace_token_deductions}
            deleteGraceTokenDeduction={this.props.deleteGraceTokenDeduction}
            createExtraMark={this.props.createExtraMark}
            destroyExtraMark={this.props.destroyExtraMark}
          />
        </TabPanel>
        {this.canShowSubmissionInfoPanel() && (
          <TabPanel>
            <SubmissionInfoPanel
              currentTags={this.props.current_tags}
              availableTags={this.props.available_tags}
              due_date={this.props.due_date}
              submission_time={this.props.submission_time}
              notes_count={this.props.notes_count}
              remark_submitted={this.props.remark_submitted}
              handleCreateTagButtonClick={this.props.handleCreateTagButtonClick}
              addTag={this.props.addTag}
              removeTag={this.props.removeTag}
              newNote={this.props.newNote}
              members={this.props.members}
            />
          </TabPanel>
        )}
      </Tabs>
    );
  }
}
