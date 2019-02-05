import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import {dateSort} from './Helpers/table_helpers';


export class TestRunTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: [],
      loading: true
    };
    this.testRuns = React.createRef();
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    let ajaxDetails = {};
    if (this.props.instructor_run) {
      if (this.props.instructor_view) {
        ajaxDetails = {
          url: Routes.get_test_runs_instructors_assignment_submission_result_path(
            this.props.assignment_id,
            this.props.submission_id,
            this.props.result_id),
          dataType: 'json',
        }
      } else {
        ajaxDetails = {
          url: Routes.get_test_runs_instructors_released_assignment_submission_result_path(
            this.props.assignment_id,
            this.props.submission_id,
            this.props.result_id),
          dataType: 'json',
        }
      }
    } else {
      ajaxDetails = {
        url: Routes.get_test_runs_students_assignment_automated_tests_path(
          this.props.assignment_id),
        dataType: 'json',
      }
    }
    $.ajax(ajaxDetails).then(res => {
      let rows = [];
      for (let test_run_id in res) {
        if (res.hasOwnProperty(test_run_id)) {
          let test_data = res[test_run_id];
          let row = {
            id_: test_run_id,
            'test_runs.created_at': test_data[0]['test_runs.created_at'],
            'users.user_name': test_data[0]['users.user_name'],
            'test_runs.status': test_data[0]['test_runs.status'],
            'test_results': [],
          };
          test_data.forEach(data => {
            Array.prototype.push.apply(row['test_results'], data['test_data']);
          });
          rows.push(row);
        }
      }
      this.setState({data: rows, loading: false},
        () => this.testRuns.current.setState({expanded: rows.length > 0 ? {0: true} : {}})
      );
    });
  };

  render() {
    return (
      <div>
        <ReactTable
          ref={this.testRuns}
          data={this.state.data}
          columns={[
            {
              id: 'created_at',
              accessor: row => row['test_runs.created_at'],
              Cell: ({value}) => I18n.l('time.formats.default', value),
              sortMethod: dateSort,
            },
            {
              id: 'user_name',
              accessor: row => row['users.user_name'],
              Cell: ({value}) => I18n.t('automated_tests.test_results_table.run_by') + ' ' + value,
            },
            {
              id: 'status',
              accessor: row => I18n.t('assignment.test_runs_statuses.' + row['test_runs.status'])
            }
          ]}
          SubComponent={ row => (
            <TestScriptResultTable
              data={row.original['test_results']}
            />
          )}
          noDataText={I18n.t('automated_tests.no_results')}
          getTheadThProps={ () => {
            return {
              style: {display: 'none'}
            }
          }}
          defaultSorted={[{id: 'created_at', desc: true}]}
          loading={this.state.loading}
        />
      </div>
    );
  }
}


class TestScriptResultTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      show_output: props.data[0] && 'test_results.output' in props.data[0]
    };
  }

  columns = () => [
    {
      id: 'test_group_name',
      Header: '',
      accessor: row => row['test_groups.name'],
      maxWidth: 30,
    },
    {
      id: 'name',
      Header: I18n.t('automated_tests.test_results_table.test_name'),
      accessor: row => row['test_results.name'],
      aggregate: (values, rows) => {
        if (rows.length === 0) {
          return '';
        } else {
          return rows[0]['test_group_name'];
        }
      },
    },
    {
      id: 'output',
      Header: I18n.t('automated_tests.test_results_table.output'),
      accessor: row => row['test_results.output'] || '',
      Cell: ({value}) => <pre className={'test-results-output'}>{value}</pre>,
      show: this.state.show_output,
      aggregate: _ => '',
      className: 'actual_output'
    },
    {
      id: 'test_status',
      Header: I18n.t('automated_tests.test_results_table.status'),
      accessor: row => row['test_results.status'],
      minWidth: 50,
      aggregate: _ => ''
    },
    {
      id: 'marks_earned',
      Header: I18n.t('automated_tests.test_results_table.marks_earned'),
      accessor: row => row['test_results.marks_earned'],
      minWidth: 40,
      className: 'number',
      aggregate: vals => vals.reduce((a, b) => a + b, 0),
    },
    {
      Header: I18n.t('automated_tests.test_results_table.marks_total'),
      id: 'test_results.marks_total',
      accessor: row => row['test_results.marks_total'],
      minWidth: 40,
      className: 'number',
      aggregate: vals => vals.reduce((a, b) => a + b, 0),
    }
  ];

  render() {
    const extraInfo = this.props.data[0]['test_script_results.extra_info'] || '';
    let extraInfoDisplay;
    if (extraInfo) {
      extraInfoDisplay = (
        <div>
          <h4>{I18n.t('automated_tests.test_results_table.extra_info')}</h4>
          <pre>{extraInfo}</pre>
        </div>);
    } else {
      extraInfoDisplay = '';
    }

    return (
      <div>
        <ReactTable
          data={this.props.data}
          columns={this.columns()}
          pivotBy={['test_group_name']}
          getTdProps={ (state, rowInfo) => {
            if (rowInfo) {
              return {className: `test-result-${rowInfo.row['test_status']}`}
            } else {
              return {};
            }
          }}
          PivotValueComponent={() => ''}
        />
        {extraInfoDisplay}
      </div>
    )
  }
}


export function makeTestRunTable(elem, props) {
  render(<TestRunTable {...props} />, elem);
}
