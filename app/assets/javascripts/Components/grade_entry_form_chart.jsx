import React from 'react';
import { render } from 'react-dom';

import { Bar } from 'react-chartjs-2';


export class GradeEntryCharts extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      distribution_data: {},
      column_data: {},
      info_data: {},
      options: {},
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    $.get({url: Routes.chart_data_grade_entry_form_path(this.props.assessment_id)}).then(res => {

      for (const [index, element] of res["column_breakdown_data"]["datasets"].entries()){
        element["backgroundColor"] = colours[index]
      }

      this.setState({distribution_data: res['grade_dist_data'], column_data: res['column_breakdown_data'], info_data: res['info_summary']});
    });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }



  render() {
    return (

      <div>
        <h2> <a href={Routes.edit_grade_entry_form_path(this.props.assessment_id)}>{this.state.info_data['name']} </a>  </h2>

        <div className='flex-row'>
          <Bar data={this.state.distribution_data}/>

          <div className='flex-row-expand'>
            <p>
              {this.state.info_data['date'] && (this.state.info_data['date_name'] + ' : ' + this.state.info_data['date'])}
            </p>

            <div className="grid-2-col">

              <span> {I18n.t('average')} </span>
              <span> {this.state.info_data['average']} </span>

              <span> {I18n.t('median')} </span>
              <span> {this.state.info_data['median']} </span>

              <span> {I18n.t('num_entries')} </span>
              <span> {this.state.info_data['num_entries']} </span>

              <span> {I18n.t('num_failed')} </span>
              <span> {this.state.info_data['num_fails']} </span>

              <span> {I18n.t('num_zeros')} </span>
              <span> {this.state.info_data['num_zeros']} </span>
            </div>
          </div>

        </div>

        <h3> {I18n.t('grade_entry_forms.grade_entry_item_distribution')} </h3>
        <Bar data={this.state.column_data}/>
      </div>
    );
  }
}
