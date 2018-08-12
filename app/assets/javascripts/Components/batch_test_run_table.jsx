import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";
import treeTableHOC from 'react-table/lib/hoc/treeTable';
import {SubmissionFileManager} from "./submission_file_manager";

const TreeTable = treeTableHOC(ReactTable);
const makeDefaultState = () => ({
  data: [],
  sorted: [{id: 'created_at', desc: true}],
  newData: []
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
      const result_url = Routes.edit_assignment_submission_result_path(this.props.assignment_id,newData[i].result_id,newData[i].result_id);
      newData[i].group_name = <a href={result_url}>{newData[i].group_name}</a>;
      // Change this to in_progress
      if(newData[i].status === "in_progress"){
        const stop_tests_url = Routes.stop_test_assignments_path(this.props.assignment_id);
        newData[i].action = <a href={stop_tests_url  + "?test_run_id=" + newData[i].id}>Stop test</a>;
        // increment in_progress number for this batch_id
        status[newData[i].test_batch_id].total += 1;
        status[newData[i].test_batch_id].in_progress += 1;
        newData[i].status = "in progress";
      } else {
        newData[i].time_to_service_estimate = "";
        status[newData[i].test_batch_id].total += 1;
        newData[i].action = "Test run is complete";
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
              Header: "Created At",
              accessor: "created_at"
            },
            {
              Header: "Group Name",
              accessor: "group_name",
              // If more than one value, show 'multiple'
              aggregate: vals => {
                return typeof vals[1] === 'undefined' ? vals[0] : 'multiple groups (batch)'
              },
              sortable: false,
            },
            {
              Header: "Status",
              accessor: 'status',
              aggregate: (vals, pivots) => {
                if(statuses[pivots[0].test_batch_id].in_progress == 0){
                  return "complete";
                } else {
                  return "complete: " + (statuses[pivots[0].test_batch_id].total - statuses[pivots[0].test_batch_id].in_progress) + "/" + statuses[pivots[0].test_batch_id].total;
                }
              },
              sortable: true,
              Aggregated: row => {
                return (
                  <span>
                       {row.value
                         }
                  </span>
                );
              }
            },
            {
              Header: "Estimated Remaining Time",
              accessor: 'time_to_service_estimate',
              Aggregated: <span></span>,
              sortable: false,
            },
            {
              Header: "Action",
              accessor: "action",
              sortable: false,
              aggregate: (vals, pivots) => {return [pivots[0].test_batch_id, statuses[pivots[0].test_batch_id]];},
              Aggregated: row => {
                if(row.value[1].in_progress > 0) {
                  const stop_tests_url = Routes.stop_batch_tests_assignments_path(this.props.assignment_id);
                  return <span><a href={stop_tests_url + "?test_batch_id=" + row.value[0]}>Stop batch</a></span>;
                } else{
                  return <span>All tests are complete</span>
                }
              }
            },
            {
              // Kept but hidden for now because status is using it
              Header: "Test_batch_id",
              accessor: 'test_batch_id',
              show: false
            }
          ]}
          pivotBy={["created_at"]}
          // Controlled props
          sorted={this.state.sorted}
          // Callbacks
          onSortedChange={sorted => this.setState({ sorted })}
          // Custom Sort Method to sort by latest batch run
          defaultSortMethod={ (a, b) => {
            // sorting for created_at_user_name to ensure it's sorted by date
            if (this.state.sorted[0].id === 'created_at') {
              if (typeof a === 'string' && typeof b === 'string') {
                let a_date = Date.parse(a);
                let b_date = Date.parse(b);
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

export function makeBatchTestRunTable(elem, props) {
  render(<BatchTestRunTable {...props}/>, elem);
}
