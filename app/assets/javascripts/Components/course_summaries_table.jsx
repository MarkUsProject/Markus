import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.course_summary_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({data: res});
    });
  }

  render() {
    const {data} = this.state;
    return (
      <ReactTable
        data={data}
        columns={[
          {
            Header: I18n.t('user.user_name'),
            accessor: 'user_name',
          },
          {
            Header: I18n.t('user.first_name'),
            accessor: 'first_name'
          },
          {
            Header: I18n.t('user.last_name'),
            accessor: 'last_name'
          }
        ]}
        filterable
      />
    );
  }
}

export function makeCourseSummaryTable(elem) {
  render(<CourseSummaryTable />, elem);
}
