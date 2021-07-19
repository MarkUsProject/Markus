import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: {
        average: null,
        median: null
      },
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
      for (const [index, element] of res["datasets"].entries()){
        element["label"] = I18n.t("main.weighted_total_grades") + " " + res["marking_schemes_id"][index]
        element["backgroundColor"] = colours[index]
      }
      this.setState({data: res})
    })
  };

  render() {
    return (
      <div>
        <h2>
          <a href={Routes.course_summaries_path()}>{'Grade Summary'}</a>
        </h2>

        <div className='flex-row'>
          <Bar data={this.state.data}/>

          {/*<div className='flex-row-expand'>*/}
          {/*  <div className="grid-2-col">*/}
          {/*    <span> {I18n.t('average')} </span>*/}
          {/*    <span> {this.state.info_data['average']} </span>*/}

          {/*    <span> {I18n.t('median')} </span>*/}
          {/*    <span> {this.state.info_data['median']} </span>*/}

          {/*    <span> {I18n.t('num_entries')} </span>*/}
          {/*    <span> {this.state.info_data['num_entries']} </span>*/}

          {/*    <span> {I18n.t('num_failed')} </span>*/}
          {/*    <span> {this.state.info_data['num_fails']} </span>*/}

          {/*    <span> {I18n.t('num_zeros')} </span>*/}
          {/*    <span> {this.state.info_data['num_zeros']} </span>*/}
          {/*  </div>*/}
          {/*</div>*/}

        </div>
      </div>
    )
  }
}




