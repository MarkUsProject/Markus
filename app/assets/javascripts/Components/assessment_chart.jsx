import React from "react";
import {Bar} from "react-chartjs-2";
import PropTypes from "prop-types";
import {chartScales} from "./Helpers/chart_helpers";

export class AssessmentChart extends React.Component {
  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(this.props.fetch_url)
      .then(data => data.json())
      .then(res => {
        this.setState({
          summary: res.summary,
          assessment_grade_distribution: {
            ...this.state.assessment_grade_distribution,
            data: res.assessment_data,
          },
          secondary_grade_distribution: {
            ...this.state.secondary_grade_distribution,
            data: res.secondary_assessment_data,
          },
        });
        for (const [index, element] of res.secondary_assessment_data.datasets.entries()) {
          element.backgroundColor = colours[index];
        }
        if (typeof this.props.set_chart_type_state === "function") {
          this.props.set_chart_type_state(res);
        }
      });
  };

  componentDidUpdate(prevProps, prevState) {
    if (prevProps.assessment_id !== this.props.assessment_id) {
      this.fetchData();
    }
  }

  render() {
    if (this.state.secondary_grade_distribution.data.datasets.length !== 0) {
      return (
        <React.Fragment>
          <h2>{this.props.assessment_header_content}</h2>
          {assessment_graph}
          {this.props.criteria_graph}
          <div className="distribution-graph">
            <h3>{this.props.secondary_grade_distribution_title}</h3>
            <Bar
              data={this.state.secondary_grade_distribution.data}
              options={this.state.secondary_grade_distribution.options}
              width="400"
              height="350"
            />
            {this.props.secondary_grade_distribution_link}
          </div>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          <h2>{this.props.assessment_header_content}</h2>
          {assessment_graph}
          {this.props.criteria_graph}
          <div className="distribution-graph">
            <h3>{this.props.secondary_grade_distribution_title}</h3>
            {this.props.secondary_grade_distribution_link}
          </div>
        </React.Fragment>
      );
    }
  }
}

AssessmentChart.propTypes = {
  course_id: PropTypes.number.isRequired,
  assessment_id: PropTypes.number.isRequired,
  fetch_url: PropTypes.string.isRequired,
  set_chart_type_state: PropTypes.func.isRequired,
  assessment_header_content: PropTypes.element.isRequired,
  additional_assessment_data: PropTypes.element.isRequired,
  outstanding_remark_request_link: PropTypes.element,
  secondary_grade_distribution_title: PropTypes.string.isRequired,
  criteria_graph: PropTypes.element,
  secondary_grade_distribution_link: PropTypes.element,
};
