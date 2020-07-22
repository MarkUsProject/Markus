import React from 'react';
import {render} from 'react-dom';
import { CourseSummaryTable } from './course_summaries_table';
import { DataChart } from './Helpers/data_chart';

class GradesSummaryDisplay extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columns: [],
      data: [],
      loading: true,
      datasets: [],
      legend: true,
      labels: []
    }
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
      let labels = Object.keys(res.columns).map(k => {
        return res.columns[k].Header;
      });
      if (this.props.student) {
        let student_marks = []
        Object.keys(res.columns).forEach(k => {
          if (res.data[0].assessment_marks[parseInt(k) + 1]) {
            student_marks.push(res.data[0].assessment_marks[parseInt(k) + 1].percentage);
          } else {
            student_marks.push(null);
          }
        });
        // Colors for chart are based on constants.css file, with modifications for opacity.
        this.setState({labels: labels, datasets: [{ label: I18n.t('results.your_mark'),
            data: student_marks,
            backgroundColor: 'rgba(58,106,179,0.35)',
            borderColor: '#3a6ab3',
            borderWidth: 1,
            hoverBackgroundColor: 'rgba(58,106,179,0.75)'},
          { label: I18n.t('course_summary.class_average'),
            data: res.averages, backgroundColor: 'rgba(228,151,44,0.35)',
            borderColor: '#e4972c',
            borderWidth: 1,
            hoverBackgroundColor: 'rgba(228,151,44,0.75)'}], legend: true});
      } else {
        this.setState({labels: labels, datasets: [{label: I18n.t('course_summary.class_average'),
          data: res.averages,
          backgroundColor: 'rgba(228,151,44,0.35)',
          borderColor: '#e4972c',
          borderWidth: 1,
          hoverBackgroundColor: 'rgba(228,151,44,0.75)'}], legend: false});
      }
      let tableColumns = res.columns.map((c, i) => {
        return {accessor: c.accessor + '.mark',
          className: c.className,
          minWidth: c.minWidth,
          Header: c.Header + ' (/' + res.totals[i + 1] + ')'};
      });
      this.setState({
        data: res.data,
        columns: tableColumns,
        loading: false,
      });
    });
  }

  render() {
    if (this.state.columns.length === 0 && !this.state.loading) {
      return <p>{I18n.t('course_summary.absent')}</p>;
    }
    return (<div>
      <CourseSummaryTable
        columns={this.state.columns}
        data={this.state.data}
        loading={this.state.loading}
        student={this.props.student}
      />
      <fieldset style={{display: 'flex', justifyContent: 'center'}}>
        <DataChart
          labels={this.state.labels}
          datasets={this.state.datasets}
          legend={this.state.legend}
        />
      </fieldset>
    </div>);
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
