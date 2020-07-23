import React from 'react';
import {render} from 'react-dom';
import { CourseSummaryTable } from './course_summaries_table';
import { DataChart } from './Helpers/data_chart';

class GradesSummaryDisplay extends React.Component {

  // Colors for chart are based on constants.css file, with modifications for opacity.
  averageDataSet = {
    label: I18n.t('course_summary.class_average'),
    backgroundColor: 'rgba(228,151,44,0.35)',
    borderColor: '#e4972c',
    borderWidth: 1,
    hoverBackgroundColor: 'rgba(228,151,44,0.75)'
  };

  individualDataSet = {
    label: I18n.t('results.your_mark'),
    backgroundColor: 'rgba(58,106,179,0.35)',
    borderColor: '#3a6ab3',
    borderWidth: 1,
    hoverBackgroundColor: 'rgba(58,106,179,0.75)'
  };

  constructor(props) {
    super(props);
    this.state = {
      columns: [],
      data: [],
      loading: true,
      datasets: [],
      labels: [],
      xTitle: I18n.t('activerecord.models.assessment.one'),
      yTitle: I18n.t('activerecord.models.mark.one') + ' (%)'
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
      let averages = labels.map(l => {
        if (res.averages[l]) {
          return parseFloat(res.averages[l]);
        } else {
          return null;
        }
      });
      this.averageDataSet.data = averages;
      if (this.props.student) {
        let student_marks = []
        Object.keys(res.columns).forEach(k => {
          if (res.data[0].assessment_marks[parseInt(k) + 1]) {
            student_marks.push(parseFloat(res.data[0].assessment_marks[parseInt(k) + 1].percentage));
          } else {
            student_marks.push(null);
          }
        });
        this.individualDataSet.data = student_marks;
        this.setState({labels: labels, datasets: [this.individualDataSet, this.averageDataSet]});
      } else {
        this.setState({labels: labels, datasets: [this.averageDataSet]});
      }

      res.columns.forEach((c, i) => {
        c.Header += ' (/' + (Math.round(parseFloat(res.totals[i]) * 100) / 100).toString() + ')';
      });
      this.setState({
        data: res.data,
        columns: res.columns,
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
          xTitle={this.state.xTitle}
          yTitle={this.state.yTitle}
        />
      </fieldset>
    </div>);
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
