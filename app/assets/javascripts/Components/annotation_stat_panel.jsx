import React from 'react';
import ReactTable from 'react-table';
import { render } from 'react-dom';
import ReactDOM from 'react-dom';

class AnnotationStatPanel extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      applications: null,
      details: false,
      num_times_used: props.num_used
    }
  }

  toggle = () => {
    if (this.state.applications === null) {
      this.fetchData()
    } else {
      this.setState({details: !this.state.details})
    }
  }

  columns = [
    {
      Header: I18n.t('annotations.used_by'),
      accessor: row => '(' + row['user_name'] + ') ' + row['first_name'] + ' ' + row['last_name'],
      id: 'user',
      minWidth: 200,
      maxWidth: 200,
      resizeable: false,
      PivotValue: ({value}) => value,
      filterMethod: (filter, row) => {
        return row[filter.id].toLowerCase().includes(filter.value.toLowerCase());
      }
    },
    {
      Header: I18n.t('activerecord.models.submission.one'),
      accessor: row => row['group_name'],
      id: 'group',
      aggregate: (vals, pivots) => I18n.t('annotations.used_times', {'number': pivots.length}),
      sortable: false,
      Aggregated: row => (
        <span>
          {'(' + row.value + ')'}
        </span>
      ),
      filterMethod: (filter, row) => {
        console.log(row[filter.id].toLowerCase())
        console.log(row[filter.id].toLowerCase().includes(filter.value.toLowerCase()))
        if (row._subRows === undefined){
          return row[filter.id].toLowerCase().includes(filter.value.toLowerCase())
        } else {
          return true;
        }
      },
      Cell: row => {
        return (
          <div>
            <a href={Routes.edit_assignment_submission_result_path(
              row.original['assignment_id'],
              row.original['submission_id'],
              row.original['result_id']
            )}
            >
              {row.original['group_name']}
            </a>
          </div>
        );
      },
      maxWidth: 200,
    }
  ];

  fetchData = () => {
    $.ajax({
      url: Routes.annotation_text_stats_assignment_annotation_categories_path(this.props.assignment_id),
      data: {
        annotation_text_id: this.props.annotation_id
      },
      dataType: 'json'
    }).then(res => {
      console.log(res)
      this.setState({applications: res['uses'], num_times_used: res['num_times_used'], details: true});
    });
  };

  render() {
    if (this.state.details) {
      let annotation_table =  (
        <ReactTable
          className='auto-overflow'
          data={this.state.applications}
          columns={this.columns}
          filterable
          pivotBy={['user']}
        />);
      return (<fieldset>
        <p>{I18n.t('annotations.count') + this.state.num_times_used}</p>
        <a onClick={() => this.toggle()} className='button usage-details'>
          {I18n.t('annotations.usage')}
        </a>
        {annotation_table}
      </fieldset>);
    } else {
      return (<fieldset>
        <p>{I18n.t('annotations.count') + this.state.num_times_used}</p>
        <a onClick={() => this.toggle()} className='button usage-details'>
        {I18n.t('annotations.usage')}
      </a>
      </fieldset>);
    }
  }
}


export function makeAnnotationStatPanel(elem, props) {
  return render(<AnnotationStatPanel {...props} />, elem);
}
