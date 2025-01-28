import React from "react";
import {createRoot} from "react-dom/client";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

import {withSelection, CheckboxTable} from "./markus_with_selection_hoc";
import {selectFilter} from "./Helpers/table_helpers";

class PeerReviewsManager extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      reviewerGroups: [],
      revieweeGroups: [],
      revieweeToReviewers: {},
      groupIdToName: {},
      reviewerToNumReviews: {},
      selectedReviewerInRevieweeGroups: {}, // Dict of [reviewee][reviewer]
      sections: {},
      numReviewers: 1,
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.populate_course_assignment_peer_reviews_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      {headers: {Accept: "application/json"}}
    )
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.studentsTable.resetSelection();
        this.reviewersTable.resetSelection();
        this.setState({
          reviewerGroups: res.reviewer_groups.groups,
          revieweeGroups: res.reviewee_groups.groups || [],
          revieweeToReviewers: res.reviewee_to_reviewers_map,
          groupIdToName: res.id_to_group_names_map,
          reviewerToNumReviews: res.num_reviews_map,
          sections: res.sections,
          loading: false,
        });
      });
  };

  updateNumReviewers = num => {
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
    this.setState({
      selectedReviewerInRevieweeGroups: this.state.selectedReviewerInRevieweeGroups,
    });
  };

  performButtonAction = action => {
    let reviewees = this.studentsTable ? this.studentsTable.state.selection : [];
    let reviewers = this.reviewersTable ? this.reviewersTable.state.selection : [];

    if ((action == "assign" || action == "random_assign") && reviewers.length === 0) {
      alert("No reviewers selected.");
      return;
    }

    if ((action == "assign" || action == "random_assign") && reviewees.length === 0) {
      alert("No reviewees selected.");
      return;
    }

    this.setState({loading: true});
    $.post({
      url: Routes.assign_groups_course_assignment_peer_reviews_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        actionString: action,
        selectedReviewerGroupIds: reviewers,
        selectedRevieweeGroupIds: reviewees,
        selectedReviewerInRevieweeGroups: this.state.selectedReviewerInRevieweeGroups,
        numGroupsToAssign: this.state.numReviewers,
      },
    }).then(this.fetchData);
  };

  render() {
    return (
      <div>
        <GradersActionBox
          performAction={this.performButtonAction}
          updateNumReviewers={this.updateNumReviewers}
        />
        <div className="mapping-tables">
          <div className="mapping-table">
            <ReviewersTable
              ref={r => (this.reviewersTable = r)}
              groups={this.state.reviewerGroups}
              reviewerToNumReviews={this.state.reviewerToNumReviews}
              loading={this.state.loading}
              showSections={this.props.showSections}
              sections={this.state.sections}
            />
          </div>
          <div className="mapping-table">
            <RevieweesTable
              ref={r => (this.studentsTable = r)}
              groups={this.state.revieweeGroups}
              revieweeToReviewers={this.state.revieweeToReviewers}
              groupIdToName={this.state.groupIdToName}
              onReviewerChangeInRevieweeTable={this.updatedSelectedReviewersInRevieweesTable}
              selectedReviewerInRevieweeGroups={this.state.selectedReviewerInRevieweeGroups}
              loading={this.state.loading}
              showSections={this.props.showSections}
              sections={this.state.sections}
            />
          </div>
        </div>
      </div>
    );
  }
}

PeerReviewsManager.defaultProps = {
  showSections: false,
};

class RawReviewersTable extends React.Component {
  getColumns = () => {
    return [
      {
        show: false,
        accessor: "_id",
        id: "_id",
      },
      {
        Header: I18n.t("activerecord.models.section", {count: 1}),
        accessor: "section",
        id: "section",
        show: this.props.showSections,
        minWidth: 70,
        Cell: ({value}) => {
          return value === "-" ? "" : value;
        },
        filterMethod: (filter, row) => {
          if (filter.value === "all") {
            return true;
          } else {
            return row.section === filter.value;
          }
        },
        Filter: selectFilter,
        filterOptions: Object.entries(this.props.sections).map(kv => ({
          value: kv[1],
          text: kv[1],
        })),
      },
      {
        Header: I18n.t("activerecord.attributes.peer_review.reviewer"),
        accessor: "name",
        id: "name",
      },
      {
        Header: I18n.t("activerecord.models.group.other"),
        accessor: "groups",
        className: "groups number",
        filterable: false,
      },
    ];
  };

  clearCheckboxes = () => {
    this.refs.table.clearCheckboxes();
  };

  changeSection = event => {
    this.clearCheckboxes();
    this.setState({sectionName: event.target.value});
    this.props.refresh();
  };

  render() {
    const hashmap = this.props.reviewerToNumReviews;
    const groups_data = this.props.groups.map(group => {
      let numReviews = 0;
      if (hashmap.hasOwnProperty(group._id)) {
        numReviews = hashmap[group._id];
      }
      return {
        _id: group._id,
        name: group.group_name,
        groups: numReviews,
        section: group.section,
      };
    });

    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={groups_data}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: "name",
          },
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
        accessor: "_id",
        id: "_id",
      },
      {
        Header: I18n.t("activerecord.models.section", {count: 1}),
        accessor: "section",
        id: "section",
        show: this.props.showSections,
        minWidth: 70,
        Cell: ({value}) => {
          return value === "-" ? "" : value;
        },
        filterMethod: (filter, row) => {
          if (filter.value === "all") {
            return true;
          } else {
            return row.section === filter.value;
          }
        },
        Filter: selectFilter,
        filterOptions: Object.entries(this.props.sections).map(kv => ({
          value: kv[1],
          text: kv[1],
        })),
      },
      {
        Header: I18n.t("activerecord.models.group.one"),
        accessor: "name",
        id: "name",
        filterable: true,
      },
      {
        Header: I18n.t("peer_reviews.assigned_reviewers_header"),
        accessor: "members",
        id: "members",
      },
      {
        Header: I18n.t("peer_reviews.number_assigned_reviewers"),
        accessor: "count",
        id: "count",
        className: "number",
      },
    ];
  };

  reviewerInRevieweeChange = event => {
    const {onReviewerChangeInRevieweeTable} = this.props;
    const isChecked = event.currentTarget.checked;
    const reviewerGroupId = parseInt(
      event.currentTarget.getAttribute("data-reviewer-group-id"),
      10
    );
    const revieweeGroupId = parseInt(
      event.currentTarget.getAttribute("data-reviewee-group-id"),
      10
    );
    onReviewerChangeInRevieweeTable(reviewerGroupId, revieweeGroupId, isChecked);
  };

  checkboxShouldBeChecked = (reviewee_group_id, reviewer_group_id) => {
    if (reviewee_group_id in this.props.selectedReviewerInRevieweeGroups) {
      return reviewer_group_id in this.props.selectedReviewerInRevieweeGroups[reviewee_group_id];
    } else {
      return false;
    }
  };

  render() {
    const groups_data = this.props.groups.map(group => {
      let reviewerGroups = [];
      const reviewee_group_id = group._id;
      const reviewer_ids = this.props.revieweeToReviewers[reviewee_group_id] || [];
      reviewer_ids.forEach(reviewer_group_id => {
        const reviewer_group_name = this.props.groupIdToName[reviewer_group_id];
        reviewerGroups.push(
          <div key={reviewer_group_id}>
            <input
              id={reviewer_group_id}
              type="checkbox"
              data-reviewer-group-id={reviewer_group_id}
              data-reviewee-group-id={reviewee_group_id}
              checked={this.checkboxShouldBeChecked(reviewee_group_id, reviewer_group_id)}
              onChange={this.reviewerInRevieweeChange}
            />{" "}
            {reviewer_group_name}
          </div>
        );
      });
      return {
        _id: group._id,
        name: group.group_name,
        members: reviewerGroups,
        section: group.section,
        count: reviewer_ids.length,
      };
    });

    return (
      <CheckboxTable
        ref={r => (this.checkboxTable = r)}
        data={groups_data}
        columns={this.getColumns()}
        defaultSorted={[
          {
            id: "name",
          },
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
    const {performAction} = this.props;

    return (
      <div className="rt-action-box">
        <div className="peer-review-amount-spinner">
          <span>{I18n.t("peer_reviews.number_per_group")}</span>
          <input
            type="number"
            id="peer-review-spinner"
            min={1}
            defaultValue={1}
            onChange={evt => this.props.updateNumReviewers(evt.target.value)}
          />
          <button
            id="random_assign"
            onClick={evt => performAction(evt.currentTarget.getAttribute("id"))}
          >
            <FontAwesomeIcon icon="fa-solid fa-dice" />
            {I18n.t("peer_reviews.action.random_assign")}
          </button>
        </div>
        <button id="assign" onClick={evt => performAction(evt.currentTarget.getAttribute("id"))}>
          <FontAwesomeIcon icon="fa-solid fa-user-plus" />
          {I18n.t("peer_reviews.action.assign")}
        </button>

        <button id="unassign" onClick={evt => performAction(evt.currentTarget.getAttribute("id"))}>
          <FontAwesomeIcon icon="fa-solid fa-user-minus" />
          {I18n.t("peer_reviews.action.unassign")}
        </button>
      </div>
    );
  };
}

export function makePeerReviewsManager(elem, props) {
  const root = createRoot(elem);
  root.render(<PeerReviewsManager {...props} />);
}
