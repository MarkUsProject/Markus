import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


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
    $.get({
      url: Routes.list_reviews_assignment_peer_reviews_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.setState({
        peer_reviews: res,
        loading: false,
      });
    });
  };

  columns = () => [
    {
      Header: I18n.t('activerecord.models.peer_review.one'),
      accessor: 'group_name',
      Cell: row => {
        return (
          <a href={Routes.edit_assignment_result_path(this.props.assignment_id, row.original.id)}>
            {`${I18n.t('activerecord.models.peer_review.one')} ${row.index + 1}`}
          </a>
        );
      }
    },
    {
      Header: I18n.t('submissions.status'),
      accessor: 'state',
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.peer_reviews}
        columns={this.columns()}
        defaultSorted={[{id: 'name'}]}
        sortable={false}
        loading={this.state.loading}
        noDataText={I18n.t('peer_reviews.no_assigned_reviews')}
      />
    );
  }
}


export function makeStudentPeerReviewsTable(elem, props) {
  render(<StudentPeerReviewsTable {...props} />, elem);
}
