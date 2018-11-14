import React from 'react';
import {render} from 'react-dom';
// This seems to be the only file that explicitly requires this import.
import * as I18n from 'i18n-js';

import {withSelection, CheckboxTable} from './markus_with_selection_hoc';


class PeerReviewsManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      reviewerGroups: [],
      revieweeGroups: [],
      revieweeToReviewers: {},
      groupIdToName: {},
      reviewerToNumReviews: {},
      selectedReviewerInRevieweeGroups: {},  // Dict of [reviewee][reviewer]
      numReviewers: 1,
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
      this.studentsTable.resetSelection();
      this.ReviewersTable.resetSelection();
      this.setState({
        reviewerGroups: res.reviewer_groups,
        revieweeGroups: res.reviewee_groups || [],
        revieweeToReviewers: res.reviewee_to_reviewers_map,
        groupIdToName: res.id_to_group_names_map,
        reviewerToNumReviews: res.num_reviews_map,
        loading: false,
      });
    });
  };

  updateNumReviewers = (num) => {
    this.setState({numReviewers: num});
  };

  updatedSelectedReviewersInRevieweesTable = (reviewerGroupId, revieweeGroupId, isChecked) => {
    // If the reviewee is not in the dictionary, add a dictionary for the reviewee id.
    if (!(revieweeGroupId in this.state.selectedReviewerInRevieweeGroups)) {
      this.state.selectedReviewerInRevieweeGroups[revieweeGroupId] = {};
    }

    // Now add or remove the reviewee to the inner dictionary based on `isChecked`.
    if (isChecked) {
      // If the reviewer isn't in the reviewee's dictionary, put it in with a temp placeholder.
      if (!(reviewerGroupId in this.state.selectedReviewerInRevieweeGroups[revieweeGroupId])) {
        this.state.selectedReviewerInRevieweeGroups[revieweeGroupId][reviewerGroupId] = true;
      }
    } else {
      // Since we're removing by unchecking, if the key exists from the inner dictionary, delete it.
      if (reviewerGroupId in this.state.selectedReviewerInRevieweeGroups[revieweeGroupId]) {
        delete this.state.selectedReviewerInRevieweeGroups[revieweeGroupId][reviewerGroupId];
      }
    }

    // While this is technically pointless, some kind of command is needed
    // to get react to re-issue a re-rendering of its components.
    this.setState({selectedReviewerInRevieweeGroups: this.state.selectedReviewerInRevieweeGroups});
  };

  performButtonAction = (action) => {
    let reviewees = this.studentsTable ? this.studentsTable.state.selection : [];
    let reviewers = this.ReviewersTable ? this.ReviewersTable.state.selection : [];

    if ((action == 'assign' || action == 'random_assign') && reviewers.length === 0) {
      alert('No reviewers selected.');
      return;
    }

    if ((action == 'assign' || action == 'random_assign') && reviewees.length === 0) {
      alert('No reviewees selected.');
      return;
    }

    this.setState({loading: true});
    $.post({
      url: Routes.assign_groups_assignment_peer_reviews_path(this.props.assignment_id),
      data: {
        actionString: action,
        selectedReviewerGroupIds: reviewers,
        selectedRevieweeGroupIds: reviewees,
        selectedReviewerInRevieweeGroups: this.state.selectedReviewerInRevieweeGroups,
        numGroupsToAssign: this.state.numReviewers
      }
    }).then(this.fetchData);
  };

  render(){
    return (
      <div>
        <GradersActionBox
          performAction={this.performButtonAction}
          updateNumReviewers={this.updateNumReviewers}
        />
        <div className='mapping-tables'>
          <div className='mapping-table'>
            <ReviewersTable
              ref={(r) => this.ReviewersTable = r}
              groups={this.state.reviewerGroups}
              reviewerToNumReviews={this.state.reviewerToNumReviews}
              loading={this.state.loading} />
          </div>
          <div className='mapping-table'>
            <RevieweesTable
              ref={(r) => this.studentsTable = r}
              groups={this.state.revieweeGroups}
              revieweeToReviewers={this.state.revieweeToReviewers}
              groupIdToName={this.state.groupIdToName}
              onReviewerChangeInRevieweeTable={this.updatedSelectedReviewersInRevieweesTable}
              selectedReviewerInRevieweeGroups={this.state.selectedReviewerInRevieweeGroups}
              loading={this.state.loading}
              showSections={this.props.showSections}
            />
          </div>
        </div>
      </div>
    );
  }
}


class RawReviewersTable extends React.Component {
  static columns = [
    {
      show: false,
      accessor: '_id',
      id: '_id'
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

  clearCheckboxes = () => {
    this.refs.table.clearCheckboxes();
  };

  changeSection = (event) => {
    this.clearCheckboxes();
    this.setState({ sectionName: event.target.value });
    this.props.refresh();
  };

  render() {
    const hashmap = this.props.reviewerToNumReviews;
    const groups_data = this.props.groups.map(function(group) {
      let numReviews = 0;
      if (hashmap.hasOwnProperty(group.id)) {
        numReviews = hashmap[group.id];
      }
      return {
        _id: group.id,
        name: group.name,
        groups: numReviews,
        section: group.section
      };
    }.bind(this));

    return (
      <CheckboxTable
        ref={(r) => this.checkboxTable = r}

        data={groups_data}
        columns={RawReviewersTable.columns}
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


class RawRevieweesTable extends React.Component {
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

  reviewerInRevieweeChange = (event) => {
    const { onReviewerChangeInRevieweeTable } = this.props;
    const isChecked = event.currentTarget.checked;
    const reviewerGroupId = parseInt(event.currentTarget.getAttribute('data-reviewer-group-id'), 10);
    const revieweeGroupId = parseInt(event.currentTarget.getAttribute('data-reviewee-group-id'), 10);
    onReviewerChangeInRevieweeTable(reviewerGroupId, revieweeGroupId, isChecked);
  };

  checkboxShouldBeChecked = (reviewee_group_id, reviewer_group_id) => {
    let returnVal = false;
    if (reviewee_group_id in this.props.selectedReviewerInRevieweeGroups) {
      returnVal = reviewer_group_id in this.props.selectedReviewerInRevieweeGroups[reviewee_group_id];
    }
    return returnVal;
  };

  render() {
    const groups_data = this.props.groups.map(function(group) {
      let reviewerGroups = [];
      const reviewee_group_id = group.id;
      const reviewer_ids = this.props.revieweeToReviewers[reviewee_group_id];
      reviewer_ids.forEach(function(reviewer_group_id) {
        const reviewer_group_name = this.props.groupIdToName[reviewer_group_id];
        reviewerGroups.push(<div key={reviewer_group_id}>
          <input id={reviewer_group_id}
                 type='checkbox'
                 data-reviewer-group-id={reviewer_group_id}
                 data-reviewee-group-id={reviewee_group_id}
                 checked={this.checkboxShouldBeChecked(reviewee_group_id, reviewer_group_id)}
                 onChange={evt => this.reviewerInRevieweeChange(evt)}
          /> {reviewer_group_name}</div>);
      }.bind(this));

      return {
        _id: group.id,
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


const ReviewersTable = withSelection(RawReviewersTable);
const RevieweesTable = withSelection(RawRevieweesTable);


class GradersActionBox extends React.Component {
  render = () => {
    const { performAction } = this.props;
    const { updateNumReviewers } = this.props;

    return (
      <div style={{ display: 'flex' }}>
        <div className="peer-review-amount-spinner" style={{ width: '100%' }}>
          <span>Number of reviewers per group: </span>
          <input type="number" id="peer-review-spinner" min={1} defaultValue={1}
                 onChange={evt => updateNumReviewers.bind(this, evt.target.value)} />
        </div>
        <div className='rt-action-box icon'>
          <button
            className='assign-all-button'
            onClick={performAction.bind(this, 'assign')}
          >
            {'Assign Reviewer(s)'}
          </button>
          <button
            className='assign-randomly-button'
            onClick={performAction.bind(this, 'random_assign')}
          >
            {'Randomly Assign Reviewers'}
          </button>
          <button
            className='unassign-all-button'
            onClick={performAction.bind(this, 'unassign')}
          >
            {'Unassign Reviewer(s)'}
          </button>
        </div>
      </div>
    )
  };
}


export function makePeerReviewsManager(elem, props) {
  render(<PeerReviewsManager {...props} />, elem);
}
