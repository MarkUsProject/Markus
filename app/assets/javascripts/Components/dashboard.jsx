import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


class Assignment extends React.Component {
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
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      $.ajax({
        url: Routes.chart_data_assignment_path(this.props.assessment_id),
        dataType: 'json',
      }).then(res => this.setState({data: res.data, summary: res.summary}))
    }
  }

  render() {
    return (
    <div>
      <div className='flex-row'>
        <div id='assignment_<%= assignment.id %>_graph'>
          <Bar data={this.state.data} />
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
  </div>
    );
  }
}

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

  getGradeEntryFormColumnBreakdown = () => {
    // Helper function to make the AJAX request, then use its response to set the chart state
    $.ajax({
      url: Routes.column_breakdown_grade_entry_form_path(
        this.state.assessment_id
      ),
      method: 'GET',
      success: (data) => {
        // Load in background colours
        for (const [index, element] of data["datasets"].entries()){
          element["backgroundColor"] = colours[index]
        }
        this.setState({
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
            }
          },
        })
      },
    })
  }

  componentDidUpdate(prevProps, prevState) {
    if (prevState.assessment_id !== this.state.assessment_id) {
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
        // Note: these are two separate AJAX requests. Need to merge when you create the new component.
        $.get({url: Routes.grade_distribution_data_grade_entry_form_path(this.state.assessment_id)}).then(res => {
          let new_data = {labels: res['labels'], datasets: [{data: res['grade_distribution']}]};
          this.setState({data: new_data});
        });
        // Commented this one out for now.
        // this.getGradeEntryFormColumnBreakdown();
      } else if (this.state.assessment_type === 'Assignment') {
        // TODO
        // $.ajax({
        //   url: Routes.grade_distribution_graph_data_assignment_path(this.state.assessment_id),
        //   dataType: 'json',
        // }).then(res => this.setState({data: res}))
      }
    }
  }

  render() {
    if (this.state.display_course_summary) {
      return <Bar data={this.state.data} />;
    } else if (this.state.assessment_type === 'Assignment') {
      return <Assignment assessment_id={this.state.assessment_id}/>;
    } else if (this.state.assessment_type === 'GradeEntryForm') {
      return (
        <div>
          <Bar data={this.state.data} />
          <Bar data={this.state.data}
               options={this.state.options}/>

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
