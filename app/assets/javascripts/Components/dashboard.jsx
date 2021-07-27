import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';

import { AssignmentChart } from './assignment_chart'
import { GradeEntryCharts } from './grade_entry_form_chart'
import { CourseSummaryChart} from "./course_summary_chart";

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
      options: {},
    };
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.assessment_id !== this.state.assessment_id ||
        prevState.display_course_summary !== this.state.display_course_summary) {
      if (this.state.assessment_type === 'GradeEntryForm') {
        // Note: these are two separate AJAX requests. Need to merge when you create the new component.
        $.get({url: Routes.grade_distribution_data_grade_entry_form_path(this.state.assessment_id)}).then(res => {
          let new_data = {labels: res['labels'], datasets: [{data: res['grade_distribution']}]};
          this.setState({data: new_data});
        });
        // Commented this one out for now.
        // this.getGradeEntryFormColumnBreakdown();
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
      return (
        <CourseSummaryChart />
      )
    } else if (this.state.assessment_type === 'Assignment') {
      return <AssignmentChart assessment_id={this.state.assessment_id}/>;
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
