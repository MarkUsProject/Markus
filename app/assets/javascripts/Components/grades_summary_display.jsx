import React from 'react';
import {render} from 'react-dom';
import { CourseSummaryTable } from './course_summaries_table';

class GradesSummaryDisplay extends React.Component {
  constructor() {
    super();
    this.fetchData = this.fetchData.bind(this);
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData() {
    $.ajax({
      url: Routes.populate_course_summaries_path(),
      dataType: 'json',
    }).then(res => {
      this.setState({
        data: res.data,
        columns: res.columns,
        loading: false,
      });
    });
  }

  render() {
    return (<CourseSummaryTable
              student={this.props.student}
            />);
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  render(<GradesSummaryDisplay {...props} />, elem);
}
