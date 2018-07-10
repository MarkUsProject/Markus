import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      marks: [],
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.populate_course_summaries_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res.data,
        marks: res.marks,
      });
    });
  }

  nameColumns = [
    {
      Header: I18n.t('activerecord.attributes.user.user_name'),
      accessor: 'user_name',
      filterable: true,
    },
    {
      Header: I18n.t('activerecord.attributes.user.first_name'),
      accessor: 'first_name',
      filterable: true,
    },
    {
      Header: I18n.t('activerecord.attributes.user.last_name'),
      accessor: 'last_name',
      filterable: true,
    },
  ];


  render() {
    return (
      <ReactTable
        data={this.state.data}
        columns={this.nameColumns.concat(this.state.marks)}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
      />
    );
  }
}

export function makeCourseSummaryTable(elem) {
  render(<CourseSummaryTable/>, elem);
}
