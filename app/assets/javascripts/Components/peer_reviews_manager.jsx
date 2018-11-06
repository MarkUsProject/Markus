import React from 'react';
import {render} from 'react-dom';
// This seems to be the only file that explicitly requires this import.
import * as I18n from 'i18n-js';

import {withSelection, CheckboxTable} from './markus_with_selection_hoc';


class PeerReviewsManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      reviewer_groups: [],
      reviewee_groups: [],
      reviewee_to_reviewers_map: {},
      id_to_group_names_map: {},
      num_reviews_map: {},
      loading: true
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({
      url: Routes.populate_assignment_peer_reviews_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      // this.studentsTable.resetSelection();
      this.gradersTable.resetSelection();
      this.setState({
        reviewer_groups: res.reviewer_groups,
        reviewee_groups: res.reviewee_groups || [],
        reviewee_to_reviewers_map: res.reviewee_to_reviewers_map,
        id_to_group_names_map: res.id_to_group_names_map,
        num_reviews_map: res.num_reviews_map,
        loading: false,
      });
    });
  };

  assignAll = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t('groups.select_a_student'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('assignment.group.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.assign_all_grade_entry_form_marks_graders_path(this.props.grade_entry_form_id),
      data: {
        students: students,
        graders: graders
      }
    }).then(this.fetchData);
  };

  unassignAll = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t('groups.select_a_student'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('assignment.group.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.unassign_all_grade_entry_form_marks_graders_path(this.props.grade_entry_form_id),
      data: {
        students: students,
        graders: graders
      }
    }).then(this.fetchData);
  };

  unassignSingle = (student_id, grader_user_name) => {
    $.post({
      url: Routes.unassign_single_grade_entry_form_marks_graders_path(this.props.grade_entry_form_id),
      data: {
        student_id: student_id,
        grader_user_name: grader_user_name
      }
    }).then(this.fetchData);
  };

  assignRandomly = () => {
    let students = this.studentsTable.state.selection;
    let graders = this.gradersTable.state.selection;

    if (students.length === 0) {
      alert(I18n.t('groups.select_a_student'));
      return;
    }

    if (graders.length === 0) {
      alert(I18n.t('assignment.group.select_a_grader'));
      return;
    }

    $.post({
      url: Routes.randomly_assign_grade_entry_form_marks_graders_path(this.props.grade_entry_form_id),
      data: {
        students: students,
        graders: graders
      }
    }).then(this.fetchData);
  };

  render(){
    return (
      <div>
        <GradersActionBox
          assignAll={this.assignAll}
          assignRandomly={this.assignRandomly}
          unassignAll={this.unassignAll}
        />
        <div className='mapping-tables'>
          <div className='mapping-table'>
            <GradersTable
              ref={(r) => this.gradersTable = r}
              groups={this.state.reviewer_groups}
              num_reviews_map={this.state.num_reviews_map}
              loading={this.state.loading} />
          </div>
          <div className='mapping-table'>
            <MarksStudentsTable
              ref={(r) => this.studentsTable = r}
              groups={this.state.reviewee_groups}
              reviewee_to_reviewers_map={this.state.reviewee_to_reviewers_map}
              id_to_group_names_map={this.state.id_to_group_names_map}
              loading={this.state.loading}
              unassignSingle={this.unassignSingle}
              showSections={this.props.showSections}
            />
          </div>
        </div>
      </div>
    );
  }
}


class RawGradersTable extends React.Component {
  static columns = [
    {
      show: false,
      accessor: 'id',
      id: 'id'
    },
    {
      Header: 'Reviewer Groups',
      accessor: 'name',
      id: 'name'
    },
    {
      Header: 'Num Reviews',
      accessor: 'groups',
      className: 'groups',
      filterable: false
    }
  ];

  render() {
    const hashmap = this.props.num_reviews_map;
    const groups_data = this.props.groups.map(function(group) {
      let numReviews = 0;
      if (hashmap.hasOwnProperty(group.id)) {
        numReviews = hashmap[group.id];
      }
      return {
        id: group.id,
        name: group.name,
        groups: numReviews,
        section: group.section
      };
    }.bind(this));

    return (
      <CheckboxTable
        ref={(r) => this.checkboxTable = r}

        data={groups_data}
        columns={RawGradersTable.columns}
        defaultSorted={[
          {
            id: 'name'
          }
        ]}
        loading={this.props.loading}
        filterable

        {...this.props.getCheckboxProps()}
      />
    );
  }
}


class RawMarksStudentsTable extends React.Component {
  getColumns = () => {
    return [
      {
        show: false,
        accessor: '_id',
        id: '_id'
      },
      {
        Header: 'Reviewee Groups',
        accessor: 'name',
        id: 'name',
        filterable: true
      },
      {
        Header: 'Assigned Reviewers',
        accessor: 'members',
        id: 'members'
      },
      {
        Header: 'Num Assigned Reviewers',
        accessor: 'count',
        id: 'count'
      },
    ];
  };

  checkboxShouldBeChecked(reviewee_group_id, reviewer_group_id) {
    let returnVal = false;
    // if (reviewee_group_id in this.props.selectedReviewerInRevieweeGroups) {
    //   returnVal = reviewer_group_id in this.props.selectedReviewerInRevieweeGroups[reviewee_group_id];
    // }
    return returnVal;
  }

  render() {
    const groups_data = this.props.groups.map(function(group) {
      let reviewerGroups = [];
      const reviewee_group_id = group.id;
      const reviewer_ids = this.props.reviewee_to_reviewers_map[reviewee_group_id];
      reviewer_ids.forEach(function(reviewer_group_id) {
        const reviewer_group_name = this.props.id_to_group_names_map[reviewer_group_id];
        reviewerGroups.push(<div key={reviewer_group_id}>
          <input id={reviewer_group_id}
                 type='checkbox'
                 data-reviewer-group-id={reviewer_group_id}
                 data-reviewee-group-id={reviewee_group_id}
                 checked={this.checkboxShouldBeChecked(reviewee_group_id, reviewer_group_id)}
                 // onChange={this.reviewerInRevieweeChange}
          /> {reviewer_group_name}</div>);
      }.bind(this));

      return {
        id: group.id,
        name: group.name,
        members: reviewerGroups,
        section: group.section,
        count: reviewer_ids.length
      };
    }.bind(this));

    return (
      <CheckboxTable
        ref={(r) => this.checkboxTable = r}

        data={groups_data}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: 'name'
          }
        ]}
        loading={this.props.loading}
        filterable

        {...this.props.getCheckboxProps()}
      />
    );
  }
}


const GradersTable = withSelection(RawGradersTable);
const MarksStudentsTable = withSelection(RawMarksStudentsTable);


class GradersActionBox extends React.Component {
  render = () => {
    return (
      <div className='rt-action-box icon'>
        <button
          className='assign-all-button'
          onClick={this.props.assignAll}
        >
          {'Assign Reviewer(s)'}
        </button>
        <button
          className='assign-randomly-button'
          onClick={this.props.assignRandomly}
        >
          {'Randomly Assign Reviewers'}
        </button>
        <button
          className='unassign-all-button'
          onClick={this.props.unassignAll}
        >
          {'Unassign Reviewer(s)'}
        </button>
      </div>
    )
  };
}


export function makePeerReviewsManager(elem, props) {
  render(<PeerReviewsManager {...props} />, elem);
}
