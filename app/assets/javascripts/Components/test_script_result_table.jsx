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
      url: Routes.automated_tests_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({data: res});
    });
  }

  render() {
    const {data} = this.state;
    return(
      <div>
        <h2>beeppeppe</h2>
        <ReactTable
          data={data}
          columns={[
            {
              Header: "Runs",
              accessor: "test_run_id"
            },
            {
              Header: "File Name",
              accessor: 'file_name',
            },
            {
              Header: "Test Name",
              accessor: 'name'
            },
            {
              Header: "Output",
              accessor: 'actual_output',
            },
            {
              Header: "Status",
              accessor: 'completion_status'
            },
            {
              Header: "Marks",
              accessor: 'marks_earned',
              aggregate: vals => _.sum(vals)

            },
            {
              Header: "Out Of",
              accessor: 'marks_total',
              aggregate: vals => _.sum(vals)
            },
          ]}
          pivotBy={["test_run_id", "file_name"]}
          defaultExpanded={{1: true, 0: true}}
        />
      </div>
    );

  }





}


export function makeTestScriptResultTable(elem) {
  render(<TestScriptResultTable />, elem);
}
