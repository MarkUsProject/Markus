import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      grade_columns: [],
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
      let grade_column = res.marks.map(c =>
        Object.assign([],
          c)
      );
      this.setState({data: JSON.parse(res.data),grade_columns:res.marks})
    });
  }

  nameColumns = [
    {
      Header: I18n.t('activerecord.attributes.user.user_name'),
      accessor: 'user_name'
    },
    {
      Header: I18n.t('activerecord.attributes.user.first_name'),
      accessor: 'first_name',
    },
    {
      Header: I18n.t('activerecord.attributes.user.last_name'),
      accessor: 'last_name',
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.data}
        columns={this.nameColumns.concat(this.state.grade_columns)}
      />
    );

    }

}

export function makeCourseSummaryTable(elem) {
  render(<CourseSummaryTable />, elem);
}
