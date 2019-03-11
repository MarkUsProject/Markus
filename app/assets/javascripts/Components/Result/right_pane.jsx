import React from 'react';
import { render } from 'react-dom';
import { Tab, Tabs, TabList, TabPanel } from 'react-tabs';

import { MarksPanel } from './marks_panel';
import { SummaryPanel } from './summary_panel';
import { TagsPanel } from './tags_panel';


class RightPane extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      loading: true,
    };
  }

  componentDidMount() {
    window.modal_create_new_tag = new ModalMarkus('#create_new_tag');
    initializePanes();
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id
      ),
      dataType: 'json'
    }).then(res => {
      let criterionSummaryData = [];
      let subtotal = 0;
      let extraMarkSubtotal = 0;
      res.marks.forEach(data => {
        data.max_mark = parseFloat(data.max_mark);
        data.mark = data['marks.mark'];
        criterionSummaryData.push({
          criterion: data.name,
          mark: data.mark,
          old_mark: res.old_marks[`criterion_${data.criterion_type}_${data.id}`],
          max_mark: data.max_mark
        });
        subtotal += data.mark || 0;
      });
      res.extra_marks.forEach(data => {
        if (data.unit === 'points') {
          extraMarkSubtotal += data.extra_mark;
        } else { // Percentage
          extraMarkSubtotal += data.extra_mark * res.assignment_max_mark / 100;
        }
      });
      this.setState({...res, criterionSummaryData, subtotal, extraMarkSubtotal, loading: false}, fix_panes);
      if (window.submissionSelector !== undefined) {
        window.submissionSelector.fetchData();
      }
    });
  };

  /* Marks Panel */
  updateMark = (criterion_type, criterion_id, mark) => {
    if (this.state.released_to_students ||
        (this.state.assigned_criteria !== null &&
         !this.state.assigned_criteria.includes(`${criterion_type}-${criterion_id}`))) {
      return;
    }

    return $.ajax({
      url: Routes.update_mark_assignment_result_path(
        this.props.assignment_id, this.props.result_id
      ),
      method: 'POST',
      data: {
        markable_type: criterion_type,
        markable_id: criterion_id,
        mark: mark
      },
      dataType: 'text'
    }).then(data => {
      let marks = this.state.marks.map(markData => {
        if (markData.id === criterion_id && markData.criterion_type === criterion_type) {
          let newMark = {...markData};
          newMark.mark = mark;
          return newMark;
        } else {
          return markData;
        }
      });
      let items = data.split(',');
      let total = items[2];
      let marked = items[3];
      let assigned = items[4];

      if (window.submissionSelector !== undefined) {
        window.submissionSelector.fetchData();
      }
      this.setState({ marks, total });
      update_bar(marked, assigned);
    });
  };

  /* Summary panel */
  createExtraMark = (description, extra_mark) => {
    return $.ajax({
      url: Routes.add_extra_mark_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      method: 'POST',
      data: {
        extra_mark: {
          description: description,
          extra_mark: extra_mark
         }
       }
    }).then(this.fetchData)
  };

  destroyExtraMark = (id) => {
    if (!confirm(I18n.t('results.delete_extra_mark_confirm'))) {
      return;
    }

    $.ajax({
      url: Routes.remove_extra_mark_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id,
        // TODO: Fix this route so that the id refers to a Result rather than ExtraMark.
        id
      ),
      method: 'POST',
    }).then(this.fetchData)
  };

  deleteGraceTokenDeduction = (deduction_id) => {
    if (!confirm(I18n.t('grace_period_submission_rules.confirm_remove_deduction'))) {
      return;
    }

    $.ajax({
      url: Routes.delete_grace_period_deduction_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id
      ),
      method: 'POST',
      data: {deduction_id: deduction_id}
    }).then(this.fetchData)
  };


  /* Tags panel */
  canShowTagsPanel = () => {
    return !this.state.released_to_students && !this.state.is_reviewer;
  };

  addTag = (tag_id) => {
    $.post({
      url: Routes.add_tag_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
  };

  removeTag = (tag_id) => {
    $.post({
      url: Routes.remove_tag_assignment_submission_result_path(
        this.props.assignment_id, this.props.submission_id, this.props.result_id),
      data: {tag_id: tag_id}
    }).then(this.fetchData);
  };

  render() {
    if (this.state.loading) {
      return I18n.t('working');
    }

    return (
      <Tabs>
        <TabList>
          <Tab>{I18n.t('activerecord.models.mark.other')}</Tab>
          <Tab>{I18n.t('results.summary')}</Tab>
          {this.canShowTagsPanel() &&
           <Tab>{I18n.t('activerecord.models.tag.other')}</Tab>
          }
        </TabList>
        <TabPanel>
          <MarksPanel
            old_marks={this.state.old_marks}
            marks={this.state.marks}
            assigned_criteria={this.state.assigned_criteria}
            released_to_students={this.state.released_to_students}
            updateMark={this.updateMark}
          />
        </TabPanel>
        <TabPanel>
          <SummaryPanel
            old_marks={this.state.old_marks}
            marks={this.state.marks}
            released_to_students={this.state.released_to_students}
            remark_submitted={this.state.remark_submitted}
            is_reviewer={this.state.is_reviewer}
            assignment_max_mark={this.state.assignment_max_mark}
            old_total={this.state.old_total}
            total={this.state.total}
            subtotal={this.state.subtotal}
            extraMarkSubtotal={this.state.extraMarkSubtotal}
            extra_marks={this.state.extra_marks}
            criterionSummaryData={this.state.criterionSummaryData}
            graceTokenDeductions={this.state.grace_token_deductions}
            deleteGraceTokenDeduction={this.deleteGraceTokenDeduction}
            createExtraMark={this.createExtraMark}
            destroyExtraMark={this.destroyExtraMark}
          />
        </TabPanel>
        {this.canShowTagsPanel() &&
         <TabPanel>
           <TagsPanel
             currentTags={this.state.current_tags}
             availableTags={this.state.available_tags}
             remark_submitted={this.state.remark_submitted}
             addTag={this.addTag}
             removeTag={this.removeTag}
             role={this.props.role}
           />
         </TabPanel>
        }
      </Tabs>
    );
  }
}


export function makeRightPane(elem, props) {
  return render(<RightPane {...props} />, elem);
}
