import React from "react";
import {Bar} from "react-chartjs-2";

import {chartScales} from "./Helpers/chart_helpers";

export class CourseSummaryChart extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      summary: [],
      data: {
        labels: [],
        datasets: [],
      },
      options: {
        plugins: {
          legend: {
            display: true,
          },
        },
        scales: chartScales(),
      },
      loading: true,
    };
  }

  componentDidMount() {
    this.fetchData();
  }

  fetchData = () => {
    fetch(Routes.grade_distribution_course_course_summaries_path(this.props.course_id))
      .then(data => data.json())
      .then(res => {
        for (const [index, element] of res.datasets.entries()) {
          element.label = res.summary[index].name;
          element.backgroundColor = colours[index];
        }
        let data = {
          labels: res.labels,
          datasets: res.datasets,
        };

        this.setState({
          summary: res.summary,
          data: data,
          loading: false,
        });
      });
  };

  render() {
    const header = (
      <h2>
        <a href={Routes.course_course_summaries_path(this.props.course_id)}>
          {I18n.t("course_summary.title")}
        </a>
      </h2>
    );

    if (!this.state.loading && this.state.data.datasets.length === 0) {
      return (
        <React.Fragment>
          {header}
          <div>
            <h3>{I18n.t("main.create_marking_scheme")}</h3>
          </div>
        </React.Fragment>
      );
    } else {
      return (
        <React.Fragment>
          {header}

          <div className="flex-row">
            <div>
              <Bar data={this.state.data} options={this.state.options} width="500" height="450" />
            </div>

            <div className="flex-row-expand">
              {this.state.summary.map((summary, i) => (
                <React.Fragment>
                  <p>{summary.name}</p>
                  <div className="grid-2-col" key={`marking-scheme-${i}-statistics`}>
                    <span>{I18n.t("average")}</span>
                    <span>{summary.average.toFixed(2)}%</span>
                    <span>{I18n.t("median")}</span>
                    <span>{summary.median.toFixed(2)}%</span>
                  </div>
                </React.Fragment>
              ))}
            </div>
          </div>
        </React.Fragment>
      );
    }
  }
}
