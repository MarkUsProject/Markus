import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import treeTableHOC from 'react-table/lib/hoc/treeTable';

const TreeTable = treeTableHOC(ReactTable);


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
      let sub_row_map = {};
      for (let i = 0; i < res.length; i++) {
        sub_row_map[i] = true;
      }
      this.setState({
        data: res,
        expanded: {0: sub_row_map},
      });
    });
  };

  render() {
    const {data} = this.state;

    return (
      <div>
        <TreeTable
          data={data}
          columns={[
            {
              id: 'created_at_user_name',
              accessor: row => `${I18n.l('time.formats.default', row['test_runs.created_at'])}
                                (${row['users.user_name']})`,
              maxWidth: 0
            },
            {
              id: 'file_name_description',
              accessor: row => row['test_scripts.description'] ?
                                 `${row['test_scripts.file_name']} - ${row['test_scripts.description']}` :
                                 row['test_scripts.file_name']
            }
          ]}
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
            const rowData = row.original['test_data'];
            const extraInfo = row.original['test_data'][0]['extra_info'] || '';
            if ('test_results.actual_output' in rowData[0]) {
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
                  data={rowData}
                  columns={columns}
                  getTdProps={ (state, rowInfo, colInfo) => {
                    if (rowInfo) { // highlight submissions that have been collected
                      return {className: `test-result-${rowInfo.row['test_results.completion_status']}`}
                    }
                    return {};
                  }}
                />
                {extraInfo && <span>{I18n.t('automated_tests.test_results_table.extra_info')} {extraInfo}</span>}
              </div>
            );
          }}
          pivotBy={['created_at_user_name']}
          noDataText={I18n.t('automated_tests.no_results')}
          getTheadThProps={ (state, rowInfo, colInfo) => {
            return {
              style: {display: 'none'}
            }
          }}
          // Controlled props
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
            if (this.state.sorted[0].id === 'created_at_user_name') {
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
