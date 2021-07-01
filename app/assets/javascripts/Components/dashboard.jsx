import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';
import {
  column_breakdown_grade_entry_form_path,
  populate_assignment_peer_reviews_path
} from "../../../javascript/routes";


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
      gradeEntryFormChart2: {}
    };
  }

  GradeEntryFormColumnBreakdownUpdateData = (data) => {
    // Helper function to update the chart state
    let label_list = Array();
    for(let i = 0; i < 105; i+=5) {
      label_list.push(i)
    }
    let datasets = Array()
    for(let j = 0; j < data[0].length; j++){
      datasets.push({
        label: data[0][j],
        data: data[1][j],
        backgroundColor: colours[j],
      })
    }

    this.setState({
      gradeEntryFormChart2: {
        data: {
          labels: label_list,
          datasets: datasets,
        },
        options: {
          plugins: {
            tooltip: {
              callbacks: {
                title: function (tooltipItems) {
                  var baseNum = parseInt(tooltipItems[0].label);
                  if (baseNum === 0) {
                    return '0-5';
                  } else {
                    return (baseNum + 1) + '-' + (baseNum + 5);
                  }
                }
              }
            },
          }
        }
      }
    })
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.assessment_id !== this.state.assessment_id) {
      if (this.state.display_course_summary) {
        // TODO
      } else if (this.state.assessment_type === 'GradeEntryForm') {
        // Make an AJAX request to retrieve chart data
        $.ajax({
          url: column_breakdown_grade_entry_form_path(
            this.state.assessment_id
          ),
          method: 'GET',
          success: this.GradeEntryFormColumnBreakdownUpdateData
        })

      } else if (this.state.assessment_type === 'Assignment') {
        // TODO
      }
    }
  }

  render() {
    if (this.state.display_course_summary) {
      return <Bar data={this.state.data} />;
    } else if (this.state.assessment_type === 'Assignment') {
      return <Bar data={this.state.data} />;
    } else if (this.state.assessment_type === 'GradeEntryForm') {
      return (
        <div>
          <Bar data={this.state.data} />;
          <Bar data={this.state.gradeEntryFormChart2.data}
               options={this.state.gradeEntryFormChart2.options}/>;

        </div>
      );
    } else {
      return '';
    }
  }
}


export function makeDashboard(elem) {
  return render(<Dashboard />, elem);
}
