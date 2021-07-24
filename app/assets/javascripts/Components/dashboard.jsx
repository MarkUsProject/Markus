import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';
import { GradeEntryCharts } from './grade_entry_form_chart'

class Dashboard extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      assessment_id: null,
      assessment_type: null,
      display_course_summary: false,
      data: { // Fake data, from react-chartjs-2/example/src/charts/GroupedBar.js
        labels: ['1', '2', '3', '4', '5', '6'],
        datasets: [
          {
            label: '# of Red Votes',
            data: [12, 19, 3, 5, 2, 3],
            backgroundColor: 'rgb(255, 99, 132)',
          },
          {
            label: '# of Blue Votes',
            data: [2, 3, 20, 5, 1, 4],
            backgroundColor: 'rgb(54, 162, 235)',
          },
          {
            label: '# of Green Votes',
            data: [3, 10, 13, 15, 22, 30],
            backgroundColor: 'rgb(75, 192, 192)',
          },
        ],
      },
      data2: {
        data: {},
        options: {},
      },
    };
  }

  getAssignmentTaGraderBreakdown = () => {
    // Helper function to make the AJAX request, then use its response to set the chart state
    $.ajax({
      url: Routes.ta_grader_breakdown_assignment_path(
        this.state.assessment_id
      ),
      method: 'GET',
      success: (data) => {
        // Load in background colours
        for (const [index, element] of data["datasets"].entries()){
          element["backgroundColor"] = colours[index]
        }
        this.setState({
          data2: {
            data: data,
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
      },
    })
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.assessment_id !== this.state.assessment_id ||
        prevState.display_course_summary !== this.state.display_course_summary) {
      if (this.state.display_course_summary) {
        $.ajax({
          url: Routes.grade_distribution_course_summaries_path(),
          type: 'GET',
          dataType: 'json'
        }).then(res => {
          this.setState({
            data: res,
            options: {
              plugins: {
                tooltip: {
                  callbacks: {
                    title: function (tooltipItems) {
                      baseNum = tooltipItems[0].dataIndex;
                      return (baseNum) + '-' + ((baseNum + 1));
                    }
                  }
                },
              }
            },
          })
        })
      } else if (this.state.assessment_type === 'GradeEntryForm') {
      } else if (this.state.assessment_type === 'Assignment') {
        $.ajax({
          url: Routes.grade_distribution_graph_data_assignment_path(this.state.assessment_id),
          dataType: 'json',
        }).then(res => this.setState({data: res}))
        this.getAssignmentTaGraderBreakdown();
      }
    }
  }

  render() {
    if (this.state.display_course_summary) {
      return <Bar data={this.state.data} />;
    } else if (this.state.assessment_type === 'Assignment') {
      return (
        <div>
          <Bar data={this.state.data} />
          <Bar data={this.state.data2.data} options={this.state.data2.options} />
        </div>
      );
    } else if (this.state.assessment_type === 'GradeEntryForm') {
      return (
        <GradeEntryCharts assessment_id={this.state.assessment_id} />
      );
    } else {
      return '';
    }
  }
}


export function makeDashboard(elem) {
  return render(<Dashboard />, elem);
}
