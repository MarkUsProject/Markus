import React from 'react';
import {render} from 'react-dom';
import { CourseSummaryTable } from './course_summaries_table';
import { DataChart } from './Helpers/data_chart';

class GradesSummaryDisplay extends React.Component {

  // Colors for chart are based on constants.css file, with modifications for opacity.
  averageDataSet = {
    label: I18n.t('class_average'),
    backgroundColor: 'rgba(228,151,44,0.35)',
    borderColor: '#e4972c',
    borderWidth: 1,
    hoverBackgroundColor: 'rgba(228,151,44,0.75)'
  };

  medianDataSet = {
    label: I18n.t('class_median'),
    backgroundColor: 'rgba(35,192,35,0.35)',
    borderColor: '#23c023',
    borderWidth: 1,
    hoverBackgroundColor: 'rgba(35,192,35,0.75)'
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
      labels: [],
      average_data: [],
      median_data: [],
      individual_data: [],
      loading: true
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.populate_course_summaries_path(),
      dataType: 'json',
    }).then(res => this.setState({loading: false, ...res}))
  }

  compileDatasets = () => {
    if (this.props.student) {
      return [
        {...this.averageDataSet, data: this.state.average_data},
        {...this.individualDataSet, data: this.state.individual_data}
      ]
    } else {
      return [
        {...this.averageDataSet, data: this.state.average_data},
        {...this.medianDataSet, data: this.state.median_data}
      ]
    }
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
          datasets={this.compileDatasets()}
          xTitle={I18n.t('activerecord.models.assessment.one')}
          yTitle={I18n.t('activerecord.models.mark.one') + ' (%)'}
          width={'auto'}
          legend={true}
        />
      </fieldset>
    </div>);
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
