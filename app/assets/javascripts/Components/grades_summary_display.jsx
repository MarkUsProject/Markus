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
      let marks = Object.keys(res.data[0].assessment_marks).map(k => {
        return res.data[0].assessment_marks[k].percentage;
      });
      let labels = Object.keys(res.columns).map(k => {
        return res.columns[k].Header;
      });
      this.chart.current.setChart({
        marks: marks,
        labels: labels
      });
    });
  }

  render() {
    return (<div>
      <CourseSummaryTable
        columns={this.state.columns}
        data={this.state.data}
        loading={this.state.loading}
        student={this.props.student}
      />
      <fieldset width={'500'}>
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
