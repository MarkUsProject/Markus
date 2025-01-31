import React from "react";
import {createRoot} from "react-dom/client";

import {CheckboxTable, withSelection} from "./markus_with_selection_hoc";
import {markingStateColumn, getMarkingStates} from "./Helpers/table_helpers";
import {FontAwesomeIcon} from "@fortawesome/react-fontawesome";

class RawPeerReviewTable extends React.Component {
  constructor(props) {
    super(props);
    const markingStates = getMarkingStates([]);
    this.state = {
      peer_reviews: [],
      loading: true,
      marking_states: markingStates,
      markingStateFilter: "all",
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.populate_table_course_assignment_peer_reviews_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      {
        headers: {
          Acccept: "application/json",
        },
      }
    )
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res => {
        this.props.resetSelection();
        const markingStates = getMarkingStates(res);
        this.setState({
          peer_reviews: res,
          loading: false,
          marking_states: markingStates,
        });
      });
  };

  onFilteredChange = (filtered, column) => {
    const summaryTable = this.checkboxTable.getWrappedInstance();
    if (column.id != "marking_state") {
      const markingStates = getMarkingStates(summaryTable.state.sortedData);
      this.setState({marking_states: markingStates});
    } else {
      const markingStateFilter = filtered.find(filter => filter.id == "marking_state").value;
      this.setState({markingStateFilter: markingStateFilter});
    }
  };

  columns = () => [
    {
      show: false,
      accessor: "_id",
      id: "_id",
    },
    {
      Header: I18n.t("activerecord.models.peer_review.one"),
      Cell: row => {
        return (
          <a href={Routes.edit_course_result_path(this.props.course_id, row.original.result_id)}>
            {`${I18n.t("activerecord.models.peer_review.one")} ${row.original._id}`}
          </a>
        );
      },
    },
    {
      Header: I18n.t("activerecord.attributes.peer_review.reviewer"),
      accessor: "reviewer_name",
      id: "reviewer_name",
    },
    {
      Header: I18n.t("activerecord.attributes.peer_review.reviewee"),
      accessor: "reviewee_name",
      id: "reviewee_name",
    },
    markingStateColumn(this.state.marking_states, this.state.markingStateFilter, {minWidth: 70}),
    {
      Header: I18n.t("results.total_mark"),
      accessor: "final_grade",
      Cell: row => {
        const value =
          row.original.final_grade === undefined
            ? "-"
            : Math.round(row.original.final_grade * 100) / 100;
        const max_mark = Math.round(row.original.max_mark * 100) / 100;
        return value + " / " + max_mark;
      },
      className: "number",
      minWidth: 80,
      filterable: false,
      defaultSortDesc: true,
    },
  ];

  // Peer review table actions
  setMarkingStates = marking_state => {
    $.post({
      url: Routes.set_result_marking_state_course_assignment_submissions_path(
        this.props.course_id,
        this.props.assignment_id
      ),
      data: {
        peer_reviews: this.props.selection,
        marking_state: marking_state,
      },
    }).then(this.fetchData);
  };

  toggleRelease = released => {
    this.setState({loading: true}, () => {
      $.post({
        url: Routes.update_submissions_course_assignment_submissions_path(
          this.props.course_id,
          this.props.assignment_id
        ),
        data: {
          release_results: released,
          peer_reviews: this.props.selection,
        },
      })
        .then(this.fetchData)
        .catch(this.fetchData);
    });
  };

  render() {
    const {loading} = this.state;

    return (
      <div>
        <PeerReviewsActionBox
          ref={r => (this.actionBox = r)}
          disabled={this.props.selection.length === 0}
          can_manage={this.props.can_manage}
          assignment_id={this.props.assignment_id}
          selection={this.props.selection}
          releaseMarks={() => this.toggleRelease(true)}
          unreleaseMarks={() => this.toggleRelease(false)}
          completeResults={() => this.setMarkingStates("complete")}
          incompleteResults={() => this.setMarkingStates("incomplete")}
          authenticity_token={this.props.authenticity_token}
        />
        <CheckboxTable
          ref={r => (this.checkboxTable = r)}
          data={this.state.peer_reviews}
          columns={this.columns()}
          defaultSorted={[
            {
              id: "reviewer_name",
            },
            {
              id: "reviewee_name",
            },
          ]}
          filterable
          defaultFiltered={this.props.defaultFiltered}
          onFilteredChange={this.onFilteredChange}
          loading={loading}
          {...this.props.getCheckboxProps()}
        />
      </div>
    );
  }
}

let PeerReviewTable = withSelection(RawPeerReviewTable);
PeerReviewTable.defaultProps = {
  can_manage: false,
};

class PeerReviewsActionBox extends React.Component {
  render = () => {
    let completeButton, incompleteButton, releaseMarksButton, unreleaseMarksButton;

    completeButton = (
      <button onClick={this.props.completeResults} disabled={this.props.disabled}>
        <FontAwesomeIcon icon="fa-solid fa-circle-check" />
        {I18n.t("results.set_to_complete")}
      </button>
    );

    incompleteButton = (
      <button onClick={this.props.incompleteResults} disabled={this.props.disabled}>
        <FontAwesomeIcon icon="fa-solid fa-pen" />
        {I18n.t("results.set_to_incomplete")}
      </button>
    );
    if (this.props.can_manage) {
      releaseMarksButton = (
        <button disabled={this.props.disabled} onClick={this.props.releaseMarks}>
          <FontAwesomeIcon icon="fa-solid fa-envelope-circle-check" />
          {I18n.t("submissions.release_marks")}
        </button>
      );
      unreleaseMarksButton = (
        <button disabled={this.props.disabled} onClick={this.props.unreleaseMarks}>
          <FontAwesomeIcon icon="fa-solid fa-envelope-circle-check" />
          {I18n.t("submissions.unrelease_marks")}
        </button>
      );
    }

    return (
      <div className="rt-action-box">
        {completeButton}
        {incompleteButton}
        {releaseMarksButton}
        {unreleaseMarksButton}
      </div>
    );
  };
}

export function makePeerReviewTable(elem, props) {
  const root = createRoot(elem);
  const component = React.createRef();
  root.render(<PeerReviewTable {...props} ref={component} />);
  return component;
}
