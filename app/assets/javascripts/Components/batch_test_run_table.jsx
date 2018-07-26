import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";
import {SubmissionFileManager} from "./submission_file_manager";

const makeDefaultState = () => ({
  data: [],
  newData: []
});

class BatchTestRunTable extends React.Component {

  constructor() {
    super();
    this.state = makeDefaultState();
    this.fetchData = this.fetchData.bind(this);
    this.addButtons = this.addButtons.bind(this);
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

  addButtons(){
    var newData = this.state.data;
    console.log(newData[0]);
    for(let i = 0; i < this.state.data.length; i++){
      if(newData[i].status === "complete"){
        const stop_tests_url = Routes.stop_tests_assignment_path(this.props.assignment_id);
        newData[i].action = <a href={stop_tests_url}>Stop test {newData[i].id}</a>;
        const result_url = Routes.edit_assignment_submission_result_path(this.props.assignment_id,newData[i].result_id,newData[i].result_id);
        newData[i].group_name = <a href={result_url}>{newData[i].group_name}</a>;
      }
    }
    this.setState({newData: newData});
  }

  render() {
    console.log("render");
    var {data} = this.state;
    // Set the row map to expand the latest test run when the webpage is loaded

    return(
      <div>
        <ReactTable
          data={this.state.newData}
          columns={[
            {
              Header: "Batch Test ID",
            accessor: "test_batch_id"
          },
          {
            Header: "Date/Time",
            accessor: "created_at"
          },
          {
            Header: "Group Name",
            accessor: "group_name"
          },
          {
            Header: "Estimated Remaining Time",
            accessor: "time_to_service_estimate"
          },
          {
            Header: "Status",
            accessor: "status"
          },{
              Header: "Action",
              accessor: "action"
            }
            ]}
          onFetchData={this.addButtons}
        />
      </div>
    );
  }
}

export function makeBatchTestRunTable(elem, props) {
  render(<BatchTestRunTable {...props}/>, elem);
}
