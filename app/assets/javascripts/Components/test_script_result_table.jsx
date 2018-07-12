import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';

const reducer = (accumulator, currentValue) => accumulator + currentValue;
const makeDefaultState = () => ({
  data: [],
  expanded: {}
});

class TestScriptResultTable extends React.Component {
  constructor() {
    super();
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.get_test_runs_results_assignment_submission_result_path(
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
    // Set the row map to expand the latest test run
    let sub_row_map = {};
    for(let i = 0; i<this.state.data.length; i++){
      sub_row_map[i] = true;
    }
    this.state.expanded = {0: sub_row_map};

    return(
      <div>
        <h2>New React Table</h2>
        <ReactTable
          data={data}
          columns={[
            {
              Header: I18n.t('automated_tests.test_results_table.time'),
              accessor: "created_at",
              Cell: row => {
                return row.value
              }
            },
            {
              Header: I18n.t('automated_tests.test_results_table.file_name'),
              accessor: 'file_name',
              Aggregated: <span></span>
            },
            {
              Header: I18n.t('automated_tests.test_results_table.test_name'),
              accessor: 'name',
              Aggregated: <span></span>
            },
            {
              Header: I18n.t('automated_tests.test_results_table.output'),
              accessor: 'actual_output',
              Aggregated: <span></span>
            },
            {
              Header: I18n.t('automated_tests.test_results_table.status'),
              accessor: 'completion_status',
              Aggregated: <span></span>
            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_earned'),
              accessor: 'marks_earned',
              aggregate: vals => vals.reduce(reducer)
            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_total'),
              accessor: 'marks_total',
              aggregate: vals => vals.reduce(reducer)
            },
          ]}
          pivotBy={["created_at", "file_name"]}
          defaultSorted={[
            {
              id: "created_at",
              desc: true
            }
          ]}
          getTrProps={this.getTrProps}
          // Controlled props
          expanded={this.state.expanded}
          // Callbacks
          onExpandedChange={expanded => this.setState({ expanded })}
        />
      </div>
    );
  }
}

export function makeTestScriptResultTable(elem, props) {
  render(<TestScriptResultTable {...props}/>, elem);
}
