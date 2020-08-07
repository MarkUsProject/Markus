import React from 'react';
import {render} from 'react-dom';

export class DataChart extends React.Component {

  componentDidMount() {
    let ctx = document.getElementById('term_marks').getContext('2d');

    let data = {
      labels: this.props.labels,
      datasets: this.props.datasets
    };

    let options = {
      responsive: false,
      legend: {
        display: this.props.legend
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0,
            max: 100
          },
          scaleLabel: {
            display: true,
            labelString: this.props.yTitle
          }
        }],
        xAxes: [{
          scaleLabel: {
            display: true,
            labelString: this.props.xTitle
          }
        }]
      }
    };

    this.chart = new Chart(ctx, {
      type: 'bar',
      data: data,
      options: options
    });
  }

  componentDidUpdate() {
    let yRange = [100];
    this.props.datasets.forEach(d => {
      yRange = yRange.concat(d.data);
    });
    this.chart.data = {labels: this.props.labels, datasets: this.props.datasets};
    this.chart.options.scales.yAxes[0].ticks.max = Math.max(...yRange);
    this.chart.options.legend.display = this.props.legend;
    this.chart.options.scales.yAxes[0].scaleLabel = {display: true, labelString: this.props.yTitle};
    this.chart.options.scales.xAxes[0].scaleLabel = {display: true, labelString: this.props.xTitle};
    this.chart.update();
  }

  render() {
    return (
      <canvas id='term_marks' style={{display: 'inline-flex', width: this.props.width, height: 500, margin: '10px'}}></canvas>
    );
  }
}

export function makeDataChart(elem, props) {
  render(<DataChart {...props} />, elem);
}
