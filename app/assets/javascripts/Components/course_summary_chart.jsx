import React from 'react';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: [],
        median: []
      },
      summary_chart_data: {
        labels: [],
        datasets: [
          {
            data: [0] // temp data so that 'Create a Marking Scheme to display course summary graph' renders properly
          }
        ],
        options: {}
      },
      marking_scheme_ids: [],
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
        let options = {
          plugins: {
            tooltip: {
              callbacks: {
                title: function (tooltipItems) {
                  let baseNum = tooltipItems[0].dataIndex;
                  return (baseNum * 5) + '-' + (baseNum * 5 + 5)
                }
              }
            },
            legend: {
              display: true
            }
          }
        };

        let data = {
          labels: res['labels'],
          datasets: res['datasets'],
          options: options
        }

        this.setState({
          summary: res['summary'],
          marking_scheme_ids: res["marking_schemes_id"],
          summary_chart_data: data
        })
      })
  };

  render() {
    if (this.state.summary_chart_data.datasets.length === 0) {
      return (
        <div>
          <h2>
            <a href={Routes.course_summaries_path()}>{I18n.t('course_summary.title')}</a>
          </h2>
          <h3>{I18n.t('main.create_marking_scheme')}</h3>
        </div>
      );
    }
    else {
      return (
        <div>
          <h2>
            <a href={Routes.course_summaries_path()}>{I18n.t('course_summary.title')}</a>
          </h2>

          <div className='flex-row'>
            <div>
              <Bar data={this.state.summary_chart_data} options={this.state.summary_chart_data.options} width='500' height='450'/>
            </div>

            <div className='flex-row-expand'>
              {this.state.marking_scheme_ids.map((_, i) =>
                <div className='grid-2-col' key={`marking-scheme-${i}-statistics`}>
                  <span> {I18n.t('activerecord.models.marking_scheme.one')}</span>
                  <span> {this.state.marking_scheme_ids[i]} </span>
                  <span> {I18n.t('average')} </span>
                  <span> {this.state.summary.average[i]} </span>
                  <span> {I18n.t('median')} </span>
                  <span> {this.state.summary.median[i]} </span>
                </div>
              )}
            </div>
          </div>
        </div>
      )
    }
  }
}




