import React from 'react';
import { Bar } from 'react-chartjs-2';


export class GradeEntryFormChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      distribution_data: { labels: [], datasets: [], options: {} } ,
      distribution_options: {
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
      },
      info_data: {},
      column_data: {
        labels: [],
        datasets: [],
        options: {
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
      }
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.grade_distribution_grade_entry_form_path(this.props.assessment_id))
      .then(data => data.json())
      .then(res => {
      for (const [index, element] of res['column_breakdown_data']['datasets'].entries()) {
        element['backgroundColor'] = colours[index];
      }
      this.setState({
        distribution_data: res['grade_dist_data'],
        column_data: { ...res['column_breakdown_data'], ...this.state.column_data.options },
        info_data: res['info_summary']
      });
    });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }

  render() {
    return (
      <React.Fragment>
        <h2>
          <a href={Routes.edit_grade_entry_form_path(this.props.assessment_id)}>{this.state.info_data.name}</a>
        </h2>
        <div className='flex-row'>
          <div>
            <Bar data={this.state.distribution_data} options={this.state.distribution_options}
                 width='500' height='450'/>
          </div>

          <div className='flex-row-expand'>
            <p>
              {this.state.info_data.date && (I18n.t('attributes.date') + ' : ' + this.state.info_data.date)}
            </p>

            <div className="grid-2-col">
              <span>{I18n.t('average')}</span>
              <span>{(this.state.info_data.average || 0).toFixed(2)}%</span>
              <span>{I18n.t('median')}</span>
              <span>{(this.state.info_data.median || 0).toFixed(2)}%</span>
              <span>{I18n.t('num_entries')}</span>
              <span>{this.state.info_data.num_entries}</span>
              <span>{I18n.t('num_failed')}</span>
              <span>{this.state.info_data.num_fails}</span>
              <span>{I18n.t('num_zeros')}</span>
              <span>{this.state.info_data.num_zeros}</span>
            </div>
          </div>
        </div>

        <h3>{I18n.t('grade_entry_forms.grade_entry_item_distribution')}</h3>
        <Bar data={this.state.column_data} options={this.state.column_data.options} width='400' height='350'/>
      </React.Fragment>
    );
  }
}
