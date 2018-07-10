import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class CourseSummaryTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      assignment_marks: [],
      grade_entry_forms: [],
      schemes: [],
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
        assignment_marks: res.assignment_marks,
        grade_entry_forms: res.grade_entry_forms,
      });
      if (this.props.is_admin){
        this.setState({schemes: res.schemes})
      }
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

  generateColumns() {
    let columns = this.nameColumns.concat(this.state.assignment_marks)
      .concat(this.state.grade_entry_forms)
    if (this.props.is_admin){
      columns.concat(this.state.schemes)
    }
    return columns
  }

  render() {
    return (
      <ReactTable
        data={this.state.data}
        columns={this.generateColumns()}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
      />
    );
  }
}

export function makeCourseSummaryTable(elem, props) {
  render(<CourseSummaryTable {...props} />, elem);
}
