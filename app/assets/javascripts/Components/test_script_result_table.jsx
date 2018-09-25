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
      sorted: [{id: 'created_at_user_name', desc: true}],
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    if (this.props.detailed) {
      var ajaxDetails = {
        url: Routes.get_test_runs_results_assignment_submission_result_path(
          this.props.assignment_id,
          this.props.submission_id,
          this.props.result_id),
        dataType: 'json',
      }
    } else {
      var ajaxDetails = {
        url: Routes.get_student_test_runs_results_assignment_automated_tests_path(
          this.props.assignment_id),
          dataType: 'json',
      }
    }
    $.ajax(ajaxDetails).then(res => {
      let sub_row_map = {};
      for (let i = 0; i < res.length; i++) {
        sub_row_map[i] = true;
        if (!(res[i]['actual_output'])) {
          res[i]['actual_output'] = '';
        }
      }
      this.setState({
        data: res,
        expanded: {0: sub_row_map},
      });
    });
  };

  // Custom getTdProps function to highlight submissions that have been collected.
  getTdProps = (state, rowInfo, colInfo) => {
    if (rowInfo) {
      return {
        className: 'test-result-' + rowInfo.row.completion_status
      }
    }
    return {};
  };

  render() {
    const {data} = this.state;

    return (
      <div>
        <TreeTable
          data={data}
          columns={[
            {
              accessor: 'created_at_user_name'
            },
            {
              accessor: 'file_name'
            }
          ]}
          subComponent={ row => {
            return (
              <ReactTable
                 data={row.original['test_data']}
                 columns={[{
                   Header: I18n.t('automated_tests.test_results_table.test_name'),
                   accessor: 'name'
                 },
                 {
                   Header: I18n.t('automated_tests.test_results_table.output'),
                   accessor: 'actual_output',
                   className: 'actual_output',
                   show: this.props.detailed
                 },
                 {
                   Header: I18n.t('automated_tests.test_results_table.status'),
                   accessor: 'completion_status',
                   minWidth: 50
                 },
                 {
                   Header: I18n.t('automated_tests.test_results_table.marks_earned'),
                   accessor: 'test_results.marks_earned',
                   minWidth: 40,
                   className: 'number'
                 },
                 {
                   Header: I18n.t('automated_tests.test_results_table.marks_total'),
                   accessor: 'test_results.marks_total',
                   minWidth: 40,
                   className: 'number'
                 }]}
              /> );
          }}
          pivotBy={['created_at_user_name', 'file_name']}
          getTdProps={this.getTdProps}
          // Controlled props
          expanded={this.state.expanded}
          resized={this.state.resized}
          sorted={this.state.sorted}
          // Callbacks
          onExpandedChange={expanded =>
            this.setState({ expanded })}
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
