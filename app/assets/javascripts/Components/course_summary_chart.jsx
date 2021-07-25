import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: [],
        median: []
      },
      summary_chart_data: [],
      marking_scheme_ids: [],
      options: []
    }
  }
  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.grade_distribution_course_summaries_path())
      .then(data => data.json())
      .then(res => {
        for (const [index, element] of res["datasets"].entries()){
          element["label"] = I18n.t("main.weighted_total_grades") + " " + res["marking_schemes_id"][index]
          element["backgroundColor"] = colours[index]
        }
        let options = []

        for (const [index, _ ] of res["label_multiplier"].entries()) {
          options.push({
            plugins: {
              tooltip: {
                callbacks: {
                  title: function (tooltipItems) {
                    let baseNum = tooltipItems[0].dataIndex;
                    return (baseNum * res["label_multiplier"][index]) + '-' + ((baseNum + 1) * res["label_multiplier"][index]);
                  }
                }
              },
              legend: {
                display: true
              }
            }
          })
        }

        let data = []
        for (let i = 0; i < res['datasets'].length; i++) {
          data.push({
            labels: res['labels'][i],
            datasets: [res['datasets'][i]],
            // options: options[i]
          })
        }

        this.setState({summary: res['summary']})
        this.setState({marking_scheme_ids: res["marking_schemes_id"]})
        this.setState({summary_chart_data: data})
        this.setState({options: options})
      })
  };

  render() {
    return (
      <div>
        <h2>
          <a href={Routes.course_summaries_path()}>{I18n.t('course_summary.title')}</a>
        </h2>

        <div className='flex-row'>
          <Bar data={this.state.summary_chart_data[0]} options={this.state.options[0]}/>
        </div>
        <div className="grid-2-col">
          <span> {I18n.t('activerecord.models.marking_scheme.one')}</span>
          <span> {this.state.marking_scheme_ids[0]} </span>
          <span> {I18n.t('average')} </span>
          <span> {this.state.summary.average[0]} </span>
          <span> {I18n.t('median')} </span>
          <span> {this.state.summary.median[0]} </span>
        </div>
      </div>
    )
  }
}




