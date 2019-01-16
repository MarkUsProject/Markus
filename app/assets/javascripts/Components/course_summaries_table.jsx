import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {stringFilter} from './Helpers/table_helpers';

class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      columns: [],
      loading: true,
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
        columns: res.columns,
        loading: false,
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
        columns={this.nameColumns.concat(this.state.columns)}
        defaultFilterMethod={stringFilter}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
        loading={this.state.loading}
      />
    );
  }
}

export function makeCourseSummaryTable(elem) {
  render(<CourseSummaryTable/>, elem);
}
