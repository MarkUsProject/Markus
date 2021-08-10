import React from 'react';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: [],
      summary_grade_distribution: {
        labels: [],
        datasets: [],
        options: {}
      },
      loading: true
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.grade_distribution_course_summaries_path())
      .then(data => data.json())
      .then(res => {
        for (const [index, element] of res["datasets"].entries()) {
          element["label"] = `${I18n.t("main.weighted_total_grades")} (${res.summary[index].name})`;
          element["backgroundColor"] = colours[index];
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
          },
          scales: {
            y: {
              title: {
                display: true,
                text: I18n.t("main.frequency")
              }
            },
            x: {
              title: {
                display: true,
                text: I18n.t("main.grade")
              }
            }
          }
        };

        let data = {
          labels: res['labels'],
          datasets: res['datasets'],
          options: options
        };

        this.setState({
          summary: res['summary'],
          summary_grade_distribution: data,
          loading: false
        });
      })
  };

  render() {
    const header = (
      <h2>
        <a href={Routes.course_summaries_path()}>{I18n.t('course_summary.title')}</a>
      </h2>
    );

    if (!this.state.loading && this.state.summary_grade_distribution.datasets.length === 0) {
      return (
        <React.Fragment>
          {header}
          <div>
            <h3>{I18n.t('main.create_marking_scheme')}</h3>
          </div>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          {header}

          <div className='flex-row'>
            <div>
              <Bar data={this.state.summary_grade_distribution} options={this.state.summary_grade_distribution.options}
                   width='500' height='450'/>
            </div>

            <div className='flex-row-expand'>
              {this.state.summary.map((summary, i) =>
                <div className='grid-2-col' key={`marking-scheme-${i}-statistics`}>
                  <span>{I18n.t('activerecord.models.marking_scheme.one')}</span>
                  <span>{summary.name}</span>
                  <span>{I18n.t('average')}</span>
                  <span>{summary.average.toFixed(2)}%</span>
                  <span>{I18n.t('median')}</span>
                  <span>{summary.median.toFixed(2)}%</span>
                </div>
              )}
            </div>
          </div>
        </React.Fragment>
      );
    }
  }
}
