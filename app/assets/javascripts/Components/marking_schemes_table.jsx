import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';


class MarkingSchemeTable extends React.Component {
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
      url: Routes.populate_marking_schemes_path(),
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
      Header: I18n.t('marking_schemes.name'),
      accessor: 'name',
      filterable: true,
    }
  ];
  modifyColumn = [
    {
      Header: I18n.t('marking_schemes.table_modify_column'),
      Cell: ({original}) => (
        <span>
          <a
            onClick={this.refresh}
            href={original.edit_link}
            data-remote='true'>
            {I18n.t('edit')}
          </a>
          &nbsp;|&nbsp;
          <a
            href={original.delete_link}
            onClick={this.refresh}
            data-remote='true'
            data-method='delete'>
            {I18n.t('delete')}
          </a>
        </span>
      ),
      sortable: false
    },
  ];

  render() {
    return (
      <ReactTable
        data={this.state.data}
        columns={this.nameColumns.concat(this.state.marks).concat(this.modifyColumn)}
        defaultSorted = {[
          {
            id: 'name'
          }
        ]}
      />
    );
  }
}

export function makeMarkingSchemeTable(elem) {
  render(<MarkingSchemeTable/>, elem);
}
