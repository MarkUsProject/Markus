import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";
import treeTableHOC from "react-table/lib/hoc/treeTable";

const TreeTable = treeTableHOC(ReactTable);
const makeDefaultState = () => ({
  data: [],
  expanded: {},
  resized: [],
  sorted: [{id: "created_at_user_name", desc: true}],
  first_load: false
});

class TestScriptResultTable extends React.Component {

  constructor() {
    super();
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
    this.state.first_load = true;
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
    // Set the row map to expand the latest test run when the webpage is loaded
    if (this.state.first_load){
      let sub_row_map = {};
      for(let i = 0; i<this.state.data.length; i++){
        sub_row_map[i] = true;
      }
      console.log(sub_row_map);
      this.state.expanded = {0: sub_row_map};
      this.state.first_load = false;
    }

    return(
      <div>
        <TreeTable
          data={data}
          columns={[
            {
              accessor: "created_at_user_name"
            },
            {
              accessor: 'file_name'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.test_name'),
              accessor: 'name'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.output'),
              accessor: 'actual_output'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.status'),
              accessor: 'completion_status'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_earned'),
              accessor: 'marks_earned'
            },
            {
              Header: I18n.t('automated_tests.test_results_table.marks_total'),
              accessor: 'marks_total'
            },
          ]}
          pivotBy={["created_at_user_name", "file_name"]}
          getTdProps={this.getTdProps}
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
            if (this.state.sorted[0].id === "created_at_user_name"){
              if (typeof a === "string" && typeof b === "string") {
                let a_date = Date.parse(a.split('(')[0]);
                let b_date = Date.parse(b.split('(')[0]);
                return a_date > b_date ? 1 : -1;
              }
            }else{
              return a > b ? 1 : -1
            }
          }}
        />
      </div>
    );
  }
}

export function makeTestScriptResultTable(elem, props) {
  render(<TestScriptResultTable {...props}/>, elem);
}
