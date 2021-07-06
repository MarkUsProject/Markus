import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';

import {grade_distribution_course_summaries_path} from "../../../javascript/routes";

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
      }
    };
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.assessment_id !== this.state.assessment_id) {
      if (this.state.display_course_summary) {
        $.ajax({
          url: grade_distribution_course_summaries_path(),
          type: 'GET',
          dataType: 'json',
        }).then(res => {
          let data = {labels: res['labels'], datasets: res['grade distribution']}
          this.setState({data: data})
        })
      } else if (this.state.assessment_type === 'GradeEntryForm') {
        // TODO
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
          <Bar data={this.state.data} />;
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
