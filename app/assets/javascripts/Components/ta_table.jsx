import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {stringFilter} from './Helpers/table_helpers';


class TATable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
      loading: true,
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.tas_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({data: res, loading: false});
    });
  }

  render() {
    const {data} = this.state;
    return (
      <ReactTable
        data={data}
        columns={[
          {
            Header: I18n.t('activerecord.attributes.user.user_name'),
            accessor: 'user_name',
          },
          {
            Header: I18n.t('activerecord.attributes.user.first_name'),
            accessor: 'first_name'
          },
          {
            Header: I18n.t('activerecord.attributes.user.last_name'),
            accessor: 'last_name'
          },
          {
            Header: I18n.t('activerecord.attributes.user.email'),
            accessor: 'email'
          },
          {
            Header: I18n.t('actions'),
            accessor: 'id',
            Cell: data => (
              <span>
                <a href={Routes.edit_ta_path(data.value)}>
                  {I18n.t('edit')}
                </a>&nbsp;
                <a href={Routes.ta_path(data.value)}
                   data-method='delete'
                   rel='nofollow'>
                  {I18n.t('delete')}
                </a>
              </span>
            ),
            sortable: false
          }
        ]}
        filterable
        defaultFilterMethod={stringFilter}
        loading={this.state.loading}
      />
    );
  }
}

export function makeTATable(elem) {
  render(<TATable />, elem);
}
