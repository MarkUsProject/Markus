import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      // summary: {
      //   average: null,
      //   median: null
      // },
      summary: [],
      data: {
        labels: [],
        datasets: [],
      },
    };
  }
  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.ajax({
      url: Routes.grade_distribution_course_summaries_path(),
      type: 'GET',
      dataType: 'json'
    }).then(res => {
      var average;
      var median;
      for (const [index, element] of res["datasets"].entries()){
        element["label"] = I18n.t("main.weighted_total_grades") + " " + res["marking_schemes_id"][index]
        element["backgroundColor"] = colours[index]
      }
      var data = {
        labels: res['labels'],
        datasets: res['datasets']
      }
      this.setState({data: data})
      this.setState({summary: res['average']})
    })
  };

  render() {
    return (
      <div>
        <h2>
          <a href={Routes.course_summaries_path()}>{'Grades Summary'}</a>
        </h2>

        <div className='flex-row'>
          <Bar data={this.state.data}/>


          <div className='flex-row-expand'>
            <div className="grid-2-col">
              <span> {I18n.t('average')} </span>
              <span> {this.state.summary[0]} </span>

              <span> {I18n.t('median')} </span>
              {/*<span> {this.state.info_data['median']} </span>*/}

            </div>
          </div>

        </div>
      </div>
    )
  }
}




