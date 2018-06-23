import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';

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
              Header: "File Name",
              accessor: 'file_name',
            },
            {
              Header: "Test Name",
              accessor: 'name'
            },
            {
              Header: "Output",
              accessor: 'actual_output'
            },
            {
              Header: "Status",
              accessor: 'completion_status'
            },
            {
              Header: "Marks",
              accessor: 'marks_earned'
            },
            {
              Header: "Out Of",
              accessor: 'marks_total'
            },
          ]}

        />
      </div>
    );

  }





}


export function makeTestScriptResultTable(elem) {
  render(<TestScriptResultTable />, elem);
}
