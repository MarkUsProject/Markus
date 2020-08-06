import React from 'react';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import { MarksPanel } from './marks_panel';
import { SummaryPanel } from './summary_panel';
import { TagsPanel } from './tags_panel';


export class RightPane extends React.Component {
  canShowTagsPanel = () => {
    return this.props.role !== 'Student' && !this.props.is_reviewer;
  };

  render() {
    return (
      <Tabs>
        <TabList>
          <Tab>{I18n.t('activerecord.models.mark.other')}</Tab>
          <Tab>{I18n.t('results.summary')}</Tab>
          {this.canShowTagsPanel() &&
           <Tab>{I18n.t('activerecord.models.tag.other')}/{I18n.t('activerecord.models.note.other')}</Tab>
          }
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
            is_reviewer={this.props.is_reviewer}
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
        {this.canShowTagsPanel() &&
         <TabPanel>
           <TagsPanel
             currentTags={this.props.current_tags}
             availableTags={this.props.available_tags}
             notes_count={this.props.notes_count}
             remark_submitted={this.props.remark_submitted}
             addTag={this.props.addTag}
             removeTag={this.props.removeTag}
             newNote={this.props.newNote}
             role={this.props.role}
           />
         </TabPanel>
        }
      </Tabs>
    );
  }
}
