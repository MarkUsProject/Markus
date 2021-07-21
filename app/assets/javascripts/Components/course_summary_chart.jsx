import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      // summary: {
      //   average: null,
      //   median: null
      // },
      summary: [],
      data: {
        labels: [],
        datasets: [],
      },
      marking_scheme_ids: []
    };
  }
  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.grade_distribution_course_summaries_path())
      .then(data => data.json())
      .then(res => {
        var average;
        var median;
        for (const [index, element] of res["datasets"].entries()){
          element["label"] = I18n.t("main.weighted_total_grades") + " " + res["marking_schemes_id"][index]
          element["backgroundColor"] = colours[index]
        }
        let data = {
          labels: res['labels'],
          datasets: res['datasets']
        }
        this.setState({data: data})
        this.setState({summary: res['average']})
        this.setState({marking_scheme_ids: res["marking_schemes_id"]})
      })
  };

  render() {
    return (
      <div>
        <h2>
          <a href={Routes.course_summaries_path()}>{I18n.t('course_summary.title')}</a>
        </h2>

        <div className='flex-row'>
          <Bar data={this.state.data}/>
        </div>
        <div className='flex-row-expand'>
          <div className="grid-2-col">
            <span> {I18n.t('activerecord.models.marking_scheme.one')}</span>
            <span> {this.state.marking_scheme_ids[0]} </span>
            <span> {I18n.t('average')} </span>
            <span> {this.state.summary[0]} </span>
            <span> {I18n.t('median')} </span>
            {/*<span> {this.state.info_data['median']} </span>*/}
          </div>
        </div>
      </div>
    )
  }
}




