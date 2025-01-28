import React from "react";
import {createRoot} from "react-dom/client";

import ReactTable from "react-table";

class StudentPeerReviewsTable extends React.Component {
  constructor() {
    super();
    this.state = {
      peer_reviews: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(
      Routes.list_reviews_course_assignment_peer_reviews_path(
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
        this.setState({
          peer_reviews: res,
          loading: false,
        });
      });
  };

  columns = () => [
    {
      Header: I18n.t("activerecord.models.peer_review.one"),
      Cell: row => {
        return (
          <a
            href={Routes.edit_course_result_path(this.props.course_id, row.original["results.id"])}
          >
            {`${I18n.t("activerecord.models.peer_review.one")} ${row.original["peer_reviews.id"]}`}
          </a>
        );
      },
    },
    {
      Header: I18n.t("submissions.status"),
      accessor: "marking_state",
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.peer_reviews}
        columns={this.columns()}
        defaultSorted={[{id: "name"}]}
        sortable={false}
        loading={this.state.loading}
        noDataText={I18n.t("peer_reviews.no_assigned_reviews")}
      />
    );
  }
}

export function makeStudentPeerReviewsTable(elem, props) {
  const root = createRoot(elem);
  root.render(<StudentPeerReviewsTable {...props} />);
}
