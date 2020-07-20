import React from 'react';
import {render} from 'react-dom';

import ReactTable from 'react-table';
import {stringFilter} from './Helpers/table_helpers';

export class CourseSummaryTable extends React.Component {
  constructor(props) {
    super();
    this.state = {
      data: props.data,
      columns: props.columns,
      loading: props.loading,
      showHidden: false,
      filtered: [{id: 'hidden', value: false}]
    };
  }

  setTable(columns, data) {
    data.forEach(d => {
      Object.keys(d.assessment_marks).forEach(m => {
        if(d.assessment_marks[m].mark === null) {
          d.assessment_marks[m] = null;
        } else {
          d.assessment_marks[m] = d.assessment_marks[m].mark.toString();
        }
      })
    });
    this.setState({columns: columns, data: data, loading: false});
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
        data={this.state.data}
        columns={this.props.student ? this.state.columns : this.nameColumns.concat(this.state.columns)}
        defaultFilterMethod={stringFilter}
        defaultSorted={[
          {
            id: 'user_name'
          }
        ]}
        loading={this.state.loading}
        filtered={this.state.filtered}
        onFilteredChange={(filtered) => this.setState({filtered})}
      />
    ];
  }
}
