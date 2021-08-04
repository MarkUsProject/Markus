import React from 'react';

import { Bar } from 'react-chartjs-2';
import {
  assignment_graders_path,
  edit_assignment_grader_path,
  global_actions_assignment_graders_path
} from "../../../javascript/routes";


export class AssignmentChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: null,
        median: null,
        num_submissions_collected: null,
        num_submissions_graded: null,
        num_fails: null,
        num_zeros: null,
        groupings_size: null
      },
      assignment_chart_data: {
        data: {
          labels: [],
          datasets: []
        },
        options: {}
      },
      ta_chart_data: {
        data: {
          labels: [],
          datasets: []
        },
        options: {}
      }
    }
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.chart_data_assignment_path(this.props.assessment_id))
      .then(data => data.json())
      .then(res => {
        // Load in background colours
        for (const [index, element] of res.ta_data.datasets.entries()){
          element["backgroundColor"] = colours[index]
        }

        this.setState({
          summary: res.summary,
          assignment_chart_data: { data: res.assignment_data, options: {} },
          ta_chart_data: {
            data: res.ta_data,
            options: {
              plugins: {
                tooltip: {
                  callbacks: {
                    title: function (tooltipItems) {
                      let baseNum = parseInt(tooltipItems[0].label);
                      if (baseNum === 0) {
                        return '0-5';
                      } else {
                        return (baseNum + 1) + '-' + (baseNum + 5);
                      }
                    }
                  }
                },
                legend: {
                  display: true
                }
              }
            },
          }
        })
      })
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id ||
      prevState.display_course_summary !== this.state.display_course_summary) {
      this.fetchData();
    }
  }

  render() {
    if (this.state.ta_chart_data['data']['datasets'].length !== 0) {
      return (
        <div>
          <h2><a href={Routes.edit_assignment_path(this.props.assessment_id)}> {this.state.summary.name} </a></h2>
          <div className='flex-row'>
            <div>
              <Bar data={this.state.assignment_chart_data.data} width='500' height='450'/>
            </div>
            <div className='flex-row-expand'>
              <div className="grid-2-col">
                <span> {I18n.t('average')} </span>
                <span> {this.state.summary.average} </span>

                <span> {I18n.t('median')} </span>
                <span> {this.state.summary.median} </span>

                <span> {I18n.t('assignments_submitted')} </span>
                <span> {this.state.summary.num_submissions_collected} / {this.state.summary.groupings_size}</span>

                <span> {I18n.t('assignments_graded')} </span>
                <span> {this.state.summary.num_submissions_graded} / {this.state.summary.groupings_size}</span>

                <span> {I18n.t('num_failed')} </span>
                <span> {this.state.summary.num_fails} </span>

                <span> {I18n.t('num_zeros')} </span>
                <span> {this.state.summary.num_zeros} </span>
              </div>
            </div>
          </div>

          <h3> {I18n.t('assignments.ta_grader_breakdown')} </h3>
          <Bar data={this.state.ta_chart_data.data} options={this.state.ta_chart_data.options} width='400'
               height='350'/>

        </div>
      );
    } else {
      return (
        <div>
          <h2><a href={Routes.edit_assignment_path(this.props.assessment_id)}> {this.state.summary.name} </a></h2>
          <div className='flex-row'>
            <div>
              <Bar data={this.state.assignment_chart_data.data} width='500' height='450'/>
            </div>
            <div className='flex-row-expand'>
              <div className="grid-2-col">
                <span> {I18n.t('average')} </span>
                <span> {this.state.summary.average} </span>

                <span> {I18n.t('median')} </span>
                <span> {this.state.summary.median} </span>

                <span> {I18n.t('assignments_submitted')} </span>
                <span> {this.state.summary.num_submissions_collected} / {this.state.summary.groupings_size}</span>

                <span> {I18n.t('assignments_graded')} </span>
                <span> {this.state.summary.num_submissions_graded} / {this.state.summary.groupings_size}</span>

                <span> {I18n.t('num_failed')} </span>
                <span> {this.state.summary.num_fails} </span>

                <span> {I18n.t('num_zeros')} </span>
                <span> {this.state.summary.num_zeros} </span>
              </div>
            </div>
          </div>

          <h4><a href={Routes.assignment_graders_path(this.props.assessment_id)}> Assign Graders</a></h4>

        </div>
      );
    }
  }
}
