import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';

const makeDefaultState = () => ({
  data: [],
  sorted: [{id: 'created_at', desc: true}],
  statuses: {}
});


class BatchTestRunTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
    this.processData = this.processData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.batch_runs_assignment_path(this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.processData(res);
    });
  }

  processData(data) {
    let status = {};
    data.forEach(row => {
      if (!(row.test_batch_id in status)) {
        status[row.test_batch_id] = {total: 0, in_progress: 0};
      }
      const result_url = Routes.edit_assignment_submission_result_path(
        this.props.assignment_id,
        row.submission_id,
        row.result_id
      );
      row.group_name = <a href={result_url}>{row.group_name}</a>;

      if (row.status === "in_progress"){
        const stop_tests_url = Routes.stop_test_assignment_path(this.props.assignment_id);
        row.action = (
          <a href={stop_tests_url  + "?test_run_id=" + row.id}>
            {I18n.t('automated_tests.stop_test')}
          </a>
        );
        // increment in_progress number for this batch_id
        status[row.test_batch_id].in_progress += 1;
        row.status = I18n.t('assignment.batch_tests_status_table.in_progress');
      } else {
        row.time_to_completion = '';
        row.action = '';
      }
      status[row.test_batch_id].total += 1;
    });
    this.setState({
      data: data,
      statuses: status
    });
  }

  render() {
    // Set the row map to expand the latest test run when the webpage is loaded
    return (
      <div>
        <ReactTable
          data={this.state.data}
          columns={[
            {
              Header: I18n.t('assignment.batch_tests_status_table.created_at'),
              accessor: 'created_at',
              minWidth: 120,
              PivotValue: ({value}) => value
            },
            {
              Header: I18n.t('assignment.batch_tests_status_table.group_name'),
              accessor: 'group_name',
              // If more than one value, show the total number of groups under this pivot
              aggregate: vals => {
                if (typeof vals[1] === 'undefined') {
                  return vals[0];
                } else {
                  const numGroups = Object.keys(vals).length;
                  return numGroups + ' ' + I18n.t('activerecord.models.groups', {count: numGroups})
                }
              },
              sortable: true,
            },
            {
              Header: I18n.t('assignment.batch_tests_status_table.status'),
              accessor: 'status',
              minWidth: 70,
              aggregate: (vals, pivots) => {
                const batch = this.state.statuses[pivots[0].test_batch_id];
                if (pivots[0].test_batch_id === null) {
                  return `${pivots[0].status}`;
                } else {
                  const total = batch.total;
                  const complete = total - batch.in_progress;
                  return `${complete} / ${total} ${I18n.t('poll_job.completed')}`;
                }
              },
              sortable: false,
              Aggregated: row => (
                <span>
                  {row.value}
                </span>
              )
            },
            {
              Header: I18n.t('assignment.batch_tests_status_table.estimated_remaining_time'),
              accessor: 'time_to_completion',
              Aggregated: <span></span>,
              sortable: false,
            },
            {
              Header: I18n.t('assignment.batch_tests_status_table.action'),
              accessor: 'action',
              minWidth: 70,
              sortable: false,
              aggregate: (vals, pivots) => {
                return [pivots[0].test_batch_id, this.state.statuses[pivots[0].test_batch_id], pivots[0].action];
              },
              Aggregated: row => {
                if (row.value[1].in_progress > 0) {
                  if (row.value[0] === null) {
                    return row.value[2];
                  } else {
                    const stop_tests_url = Routes.stop_batch_tests_assignment_path(this.props.assignment_id);
                    return <span><a href={stop_tests_url + "?test_batch_id=" + row.value[0]}>{I18n.t('automated_tests.stop_batch')}</a></span>;
                  }
                } else {
                  return '';
                }
              }
            },
            {
              // Kept but hidden because status is using it
              Header: '',
              accessor: 'test_batch_id',
              show: false
            }
          ]}
          pivotBy={['created_at']}
          // Controlled props
          sorted={this.state.sorted}
          // Callbacks
          onSortedChange={sorted => this.setState({ sorted })}
          // Custom Sort Method to sort by latest batch run
          defaultSortMethod={ (a, b) => {
            // sorting for created_at_user_name to ensure it's sorted by date
            if (this.state.sorted[0].id === 'created_at') {
              if (typeof a === 'string' && typeof b === 'string') {
                let a_date = Date.parse(a);
                let b_date = Date.parse(b);
                return a_date > b_date ? 1 : -1;
              }
            } else {
              return a > b ? 1 : -1;
            }
          }}
        />
      </div>
    );
  }
}

export function makeBatchTestRunTable(elem, props) {
  render(<BatchTestRunTable {...props}/>, elem);
}
