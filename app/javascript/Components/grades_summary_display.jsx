import React from "react";
import {createRoot} from "react-dom/client";
import {CourseSummaryTable} from "./course_summaries_table";
import {DataChart} from "./Helpers/data_chart";

class GradesSummaryDisplay extends React.Component {
  // Colors for chart are based on constants.css file, with modifications for opacity.
  averageDataSet = {
    label: I18n.t("class_average"),
    backgroundColor: "rgba(228,151,44,0.35)",
    border: {color: "#e4972c", width: 1},
    hoverBackgroundColor: "rgba(228,151,44,0.75)",
  };

  medianDataSet = {
    label: I18n.t("class_median"),
    backgroundColor: "rgba(35,192,35,0.35)",
    border: {color: "#23c023", width: 1},
    hoverBackgroundColor: "rgba(35,192,35,0.75)",
  };

  individualDataSet = {
    label: I18n.t("results.your_mark"),
    backgroundColor: "rgba(58,106,179,0.35)",
    border: {color: "#3a6ab3", width: 1},
    hoverBackgroundColor: "rgba(58,106,179,0.75)",
  };

  constructor(props) {
    super(props);
    this.state = {
      assessments: [],
      marking_schemes: [],
      data: [],
      graph_labels: [],
      datasets: [],
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.populate_course_course_summaries_path(this.props.course_id), {
      headers: {
        Accept: "application/json",
      },
    })
      .then(response => {
        if (response.ok) {
          return response.json();
        }
      })
      .then(res =>
        this.setState({
          ...res,
          loading: false,
          datasets: this.compileDatasets(res.graph_data),
        })
      );
  };

  compileDatasets = data => {
    let dataset = [];
    if (!!data.average.filter(x => x !== null).length) {
      dataset.push({...this.averageDataSet, data: data.average});
    }
    if (!!data.median.filter(x => x !== null).length) {
      dataset.push({...this.medianDataSet, data: data.median});
    }
    if (!!data.individual.filter(x => x !== null).length) {
      dataset.push({...this.individualDataSet, data: data.individual});
    }
    return dataset;
  };

  render() {
    if (this.state.assessments.length === 0 && !this.state.loading) {
      return <p>{I18n.t("course_summary.absent")}</p>;
    }
    return (
      <div>
        <CourseSummaryTable
          assessments={this.state.assessments}
          marking_schemes={this.state.marking_schemes}
          data={this.state.data}
          loading={this.state.loading}
          student={this.props.student}
        />
        <fieldset className="data-chart-container">
          <DataChart
            labels={this.state.graph_labels}
            datasets={this.state.datasets}
            xTitle={I18n.t("activerecord.models.assessment.one")}
            yTitle={I18n.t("activerecord.models.mark.one") + " (%)"}
            legend={true}
          />
        </fieldset>
      </div>
    );
  }
}

export function makeGradesSummaryDisplay(elem, props) {
  const root = createRoot(elem);
  root.render(<GradesSummaryDisplay {...props} />);
}
