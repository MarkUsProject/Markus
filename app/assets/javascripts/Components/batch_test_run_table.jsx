import React from 'react';
import {render} from 'react-dom';
import ReactTable from 'react-table';
import "react-table/react-table.css";
import treeTableHOC from 'react-table/lib/hoc/treeTable';

const TreeTable = treeTableHOC(ReactTable);
const makeDefaultState = () => ({
  data: [],
  sorted: [{id: 'test_batch_id', desc: true}],
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
              Header: "Batch Test ID",
              accessor: "test_batch_id"
            },
            {
              Header: "Date/Time",
              accessor: "created_at",
              // aggregate: vals => {
              //   let earliestDate = null;
              //   for (let i in vals){
              //     console.log("type: " + typeof vals[i]);
              //     let datetime = Date.parse(vals[i]);
              //     if (earliestDate == null){
              //       earliestDate = datetime;
              //     }else{
              //       if (earliestDate > datetime){
              //         earliestDate = datetime;
              //       }
              //     }
              //   }
              //   console.log(typeof earliestDate);
              //   return earliestDate
              // },
              Aggregated: <span></span>
            },
            {
              Header: "Group Name",
              accessor: "group_name",
              Aggregated: <span></span>
            },
            {
              Header: "Estimated Remaining Time",
              accessor: 'time_to_service_estimate',
              Aggregated: <span></span>
            },
            {
              Header: "Status",
              accessor: 'status',
              Aggregated: <span><a href={"www.google.com"}>Stop This batch</a></span>
            }
          ]}
          pivotBy={["test_batch_id"]}
          // Controlled props
          sorted={this.state.sorted}
          // Callbacks
          onSortedChange={sorted => this.setState({ sorted })}
          // Custom Sort Method to sort by latest batch run
          defaultSortMethod={ (a, b) => {
            // sorting for created_at_user_name to ensure it's sorted by date
            if (this.state.sorted[0].id === 'test_batch_id') {
              if (a === 'Individual Tests'){
                return -1;
              }else if (b === 'Individual Tests'){
                return 1;
              }else{
                return parseInt(a) > parseInt(b) ? 1: -1
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
