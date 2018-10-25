import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';

class TestScriptResultTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      data: [],
      expanded: {},
      resized: [],
      sorted: [],
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  cancelTest(test_run_id) {
    $.get({
      url: Routes.stop_test_assignment_path(this.props.assignment_id),
      data: {test_run_id: test_run_id}
    })
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
      let expanded = {};
      for (let i = 0; i < res.length; i++) {
        if (res[i]['test_runs.created_at'] === res[0]['test_runs.created_at']) {
          expanded[i] = true;
        }
      }
      this.setState({
        data: res,
        expanded: expanded,
      });
    });
  };

  render() {
    const {data} = this.state;

    return (
      <div>
        <ReactTable
          data={data}
          columns={[
            {
              Header: I18n.t('assignment.batch_tests_status_table.created_at'),
              id: 'created_at',
              Cell: row => { return I18n.l('time.formats.default', row.original['test_runs.created_at']) },
            },
            {
              Header: I18n.t('automated_tests.test_results_table.run_by'),
              id: 'user_name',
              accessor: row => row['users.user_name']
            },
            {
              Header: I18n.t('automated_tests.test_results_table.status'),
              id: 'status',
              accessor: row => I18n.t('assignment.test_runs_statuses.' + row['test_runs.status'])
            }
          ]}
          SubComponent={ row => {
            let columns = [
              {
                id: 'test_script_file',
                Cell: row => {
                  let scriptName;
                  if (row.original['test_scripts.file_name'] === null) {
                    scriptName = I18n.t('automated_tests.results.unknown_test_script')
                  } else {
                    scriptName = row.original['test_scripts.file_name']
                  }
                  if (row.original['test_scripts.description']) {
                    scriptName = scriptName + '_' + row.original['test_scripts.description']
                  }
                  return <div style={{ textAlign: "center" }}>{scriptName}</div>
                }
              },
              {
                id: 'test_script_results.time',
                accessor: row => I18n.t('automated_tests.test_results_table.estimated_run_time', {time_in_seconds: row['test_script_results.time']/1000})
              },
              {
                expander: true,
                show: false
              }
            ]
            let testScriptData = row.original['test_script_data']
            let expanded = {}
            for (let i = 0; i < testScriptData.length; i++) {
              expanded[i] = true;
            }
            let scriptTable =
              <div>
                <ReactTable
                  columns={columns}
                  data={testScriptData}
                  expanded={expanded}
                  getTheadThProps={ (state, rowInfo, colInfo) => {
                    return {
                      style: {display: 'none'}
                    }
                  }}
                  SubComponent={ row => {
                    let columns = [
                      {
                        Header: I18n.t('automated_tests.test_results_table.test_name'),
                        id: 'test_scripts.name',
                        accessor: row => row['test_results.name']
                      },
                      {
                        Header: I18n.t('automated_tests.test_results_table.status'),
                        id: 'test_results.completion_status',
                        accessor: row => row['test_results.completion_status'],
                        minWidth: 50
                      },
                      {
                        Header: I18n.t('automated_tests.test_results_table.marks_earned'),
                        id: 'test_results.marks_earned',
                        accessor: row => row['test_results.marks_earned'],
                        Cell: row => {
                          let mark = row.original['test_results.marks_earned']
                          let outOf = row.original['test_results.marks_total']
                          let bonus = mark - outOf
                          if (bonus > 0){
                            return `${outOf} (+${bonus} ${I18n.t('automated_tests.test_results_table.marks_bonus')})`
                          } else {
                            return mark
                          }
                        },
                        minWidth: 40,
                        className: 'number'
                      },
                      {
                        Header: I18n.t('automated_tests.test_results_table.marks_total'),
                        id: 'test_results.marks_total',
                        accessor: row => row['test_results.marks_total'],
                        minWidth: 40,
                        className: 'number'
                      }
                    ];
                    const testResultData = row.original['test_result_data'];
                    const extraInfo = testResultData[0]['test_script_results.extra_info'] || '';
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
                    if (testResultData[0]['test_results.time'] > 0) {
                      columns.splice(1, 0, {
                        id: 'test_results.time',
                        Header: I18n.t('automated_tests.test_results_table.time'),
                        accessor: row => row['test_results.time']
                      })
                    }
                    if ('test_results.actual_output' in testResultData[0]) {
                      columns.splice(1, 0, {
                        id: 'actual_output',
                        Header: I18n.t('automated_tests.test_results_table.output'),
                        accessor: row => row['test_results.actual_output'] ? row['test_results.actual_output'] : '',
                        className: 'actual_output'
                      })
                    }
                    return (
                      <div>
                        <ReactTable
                          data={testResultData}
                          columns={columns}
                          getTdProps={ (state, rowInfo, colInfo) => {
                            if (rowInfo) { // highlight submissions that have been collected
                              return {className: `test-result-${rowInfo.row['test_results.completion_status']}`}
                            }
                            return {};
                          }}
                        />
                        {extraInfoDisplay}
                      </div>
                    );
                  }}
                />
              </div>
            if (testScriptData[0]['test_runs.status'] !== 'in_progress') {
              return ( scriptTable )
            } else if (this.props.instructor_view) {
              return (
                <div style={{ textAlign: "center" }}>
                  <button
                    onClick={this.cancelTest(testScriptData[0]['test_runs.id'])}
                  >
                    {I18n.t('automated_tests.stop_test')}
                  </button>
                </div>
              )
            }
          }}
          noDataText={I18n.t('automated_tests.no_results')}
          expanded={this.state.expanded}
          resized={this.state.resized}
          sorted={this.state.sorted}
          // Callbacks
          onExpandedChange={expanded => this.setState({ expanded })}
          onResizedChange={resized => this.setState({ resized })}
          onSortedChange={sorted => this.setState({ sorted })}
          // Custom Sort Method to sort by latest date first
          defaultSortMethod={ (a, b) => {
            // sorting for created_at_user_name to ensure it's sorted by date
            if (this.state.sorted[0].id === 'created_at') {
              if (typeof a === 'string' && typeof b === 'string') {
                let a_date = Date.parse(a.split('(')[0]);
                let b_date = Date.parse(b.split('(')[0]);
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

export function makeTestScriptResultTable(elem, props) {
  render(<TestScriptResultTable {...props} />, elem);
}
