import React from 'react';
import {render} from 'react-dom';
import { CourseSummaryTable } from './course_summaries_table';
import { DataChart } from './Helpers/data_chart';

class GradesSummaryDisplay extends React.Component {
  constructor() {
    super();
    this.state = {
      columns: [],
      data: [],
      loading: true
    }
    this.chart = React.createRef();
    this.table = React.createRef();
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.populate_course_summaries_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res.data,
        columns: res.columns,
        loading: false,
      });
      let marks = []
      let labels = Object.keys(res.columns).map(k => {
        if(res.data[0].assessment_marks[parseInt(k) + 1]) {
          marks.push(res.data[0].assessment_marks[parseInt(k) + 1].percentage);
        } else {
          marks.push(null);
        }
        return res.columns[k].Header;
      });
      if(this.props.student){
        this.chart.current.setChart([labels,
          { label: 'My Mark',
            data: marks,
            backgroundColor: 'rgba(58,106,179,0.35)',
            borderColor: '#3a6ab3',
            borderWidth: 1,
            hoverBackgroundColor: 'rgba(58,106,179,0.75)'},
          { label: 'Class Average',
            data: res.averages, backgroundColor: 'rgba(228,151,44,0.35)',
            borderColor: '#e4972c',
            borderWidth: 1,
            hoverBackgroundColor: 'rgba(228,151,44,0.75)'}], true);
      } else {
        this.chart.current.setChart([labels, {label: 'Class Average',
          data: res.averages,
          backgroundColor: 'rgba(228,151,44,0.35)',
          borderColor: '#e4972c',
          borderWidth: 1,
          hoverBackgroundColor: 'rgba(228,151,44,0.75)'}],
          false);
      }
      this.state.columns.forEach((c, i) => {
        c.Header += ' (/' + res.totals[i + 1] +')'
      })
      this.table.current.setTable(this.state.columns, this.state.data);
    });
  }

  render() {
    return (<div>
      <CourseSummaryTable
        columns={this.state.columns}
        data={this.state.data}
        loading={this.state.loading}
        ref={this.table}
        student={this.props.student}
      />
      <fieldset style={{display: 'flex', justifyContent: 'center'}}>
        <DataChart
          ref={this.chart}
        />
      </fieldset>
    </div>);
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
