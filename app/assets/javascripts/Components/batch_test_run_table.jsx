import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";

const makeDefaultState = () => ({
  data: [],
});

class BatchTestRunTable extends React.Component {

  constructor() {
    super();
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    console.log("fetch data start");
    $.ajax({
      url: Routes.batch_runs_assignment_path(
        this.props.assignment_id),
      dataType: 'json',
    }).then(res => {
      this.setState({data: res});
    });
    console.log("fetch data end");
  }

  render() {
    console.log("render");
    const {data} = this.state;
    // Set the row map to expand the latest test run when the webpage is loaded

    return(
      <div>
        <ReactTable
          data={data}
          columns={[
            {
              Header: "User Name",
              accessor: "user_name"
            },
            {
              Header: "File Name",
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
        />
      </div>
    );
  }
}

export function makeBatchTestRunTable(elem, props) {
  render(<BatchTestRunTable {...props}/>, elem);
}
