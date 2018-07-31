import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";
import {SubmissionFileManager} from "./submission_file_manager";

const makeDefaultState = () => ({
  data: [],
  newData: [],
});

var statuses = {};

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
    var status = {}
    var newData = this.state.data;
    for(let i = 0; i < this.state.data.length; i++){
      // Check if key exists in dictionary
      if(!(newData[i].test_batch_id in status)){
        // add key to dictionairy
        status[newData[i].test_batch_id] = {total: 0, in_progress: 0};
      }
      // Change this to in_progress
      if(newData[i].status === "complete"){
        const stop_tests_url = Routes.stop_tests_assignment_path(this.props.assignment_id);
        newData[i].action = <a href={stop_tests_url}>Stop test {newData[i].id}</a>;
        const result_url = Routes.edit_assignment_submission_result_path(this.props.assignment_id,newData[i].result_id,newData[i].result_id);
        newData[i].group_name = <a href={result_url}>{newData[i].group_name}</a>;
        // increment in_progress number for this batch_id
        status[newData[i].test_batch_id].total += 1;
        status[newData[i].test_batch_id].in_progress += 1;
      } else {
        newData[i].time_to_service_estimate = "";
        status[newData[i].test_batch_id].total += 1;
      }
    }
    statuses = status;
    return newData;
  }

  render() {
    // Set the row map to expand the latest test run when the webpage is loaded

    return(
      <div>
        <ReactTable
          data={this.addButtons()}
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
        />
      </div>
    );
  }
}

export function makeBatchTestRunTable(elem, props) {
  render(<BatchTestRunTable {...props}/>, elem);
}
