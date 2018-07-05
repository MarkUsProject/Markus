import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import _ from 'lodash';

class TestScriptResultTable extends React.Component {
  constructor() {
    super();
    this.state = {
      data: [],
    };
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.get_test_runs_assignment_submission_result_path(
        this.props.assignment_id,
        this.props.submission_id,
        this.props.result_id),
      dataType: 'json',
    }).then(res => {
      this.setState({data: res});
    });
  }

  // Custom getTrProps function to highlight submissions that have been collected.
  getTrProps = (state, rowInfo, colInfo, instance) => {
    if (rowInfo) {
      return {
        className: 'test-result-' + rowInfo.row.completion_status
      }
    }
    return {};
  };

  render() {
    const {data} = this.state;
    return(
      <div>
        <h2>New React Table</h2>
        <ReactTable
          data={data}
          columns={[
            {
              Header: I18n.t('automated_tests.test_results_table.test_runs'),
              accessor: "test_run_id"
            },
            {
              Header: I18n.t('automated_tests.test_results_table.file_name'),
              accessor: 'file_name',
            },
            {
              Header: I18n.t('automated_tests.test_results_table.test_name'),
              accessor: 'name'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.output'),
              accessor: 'actual_output',
            },
            {
              Header: I18n.t('automated_tests.test_results_table.status'),
              accessor: 'completion_status'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_earned'),
              accessor: 'marks_earned',
              aggregate: vals => _.sum(vals)

            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_total'),
              accessor: 'marks_total',
              aggregate: vals => _.sum(vals)
            },
          ]}
          pivotBy={["test_run_id", "file_name"]}
          // defaultExpanded={{1: true, 0: true}}
          getTrProps={this.getTrProps}
        />
      </div>
    );

  }
}

export function makeTestScriptResultTable(elem, props) {
  render(<TestScriptResultTable {...props}/>, elem);
}
