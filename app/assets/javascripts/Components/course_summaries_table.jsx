import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {stringFilter} from './Helpers/table_helpers';

export class CourseSummaryTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      showHidden: false,
      filtered: [{id: 'hidden', value: false}]
    };
  }

  nameColumns = [
    {
      id: 'hidden',
      accessor: 'hidden',
      filterMethod: (filter, row) => {
        return filter.value || !row.hidden;
      },
      className: 'rt-hidden',
      headerClassName: 'rt-hidden',
      resizable: false,
      width: 0,
    },
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

  updateShowHidden = (event) => {
    let showHidden = event.target.checked;
    let filtered = [];
    for (let i = 0; i < this.state.filtered.length; i++) {
      if (this.state.filtered[i].id !== 'hidden') {
        filtered.push(this.state.filtered[i]);
      }
    }
    if (!showHidden) {
      filtered.push({id: 'hidden', value: false});
    }
    this.setState({filtered, showHidden});
  };

  render() {
    return [
      !this.props.student &&
      <div key='show-hidden' style={{'height': '2em'}}>
        <input
          id='show_hidden'
          name='show_hidden'
          type='checkbox'
          checked={this.state.showHidden}
          onChange={this.updateShowHidden}
          style={{marginLeft: '5px', marginRight: '5px'}}
        />
        <label htmlFor='show_hidden'>
          {I18n.t('students.display_inactive')}
        </label>
      </div>,
      <ReactTable
        key='course-summary-table'
        data={this.props.data}
        columns={this.props.student ? this.props.columns : this.nameColumns.concat(this.props.columns)}
        defaultFilterMethod={stringFilter}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
        loading={this.props.loading}
        filtered={this.state.filtered}
        onFilteredChange={(filtered) => this.setState({filtered})}
        className={'auto-overflow'}
      />
    ];
  }
}
