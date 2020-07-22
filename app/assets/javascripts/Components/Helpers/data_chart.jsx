import React from 'react';

export class DataChart extends React.Component {

  componentDidMount() {
    let ctx = document.getElementById('term_marks').getContext('2d');

    let data = {
      labels: [],
      datasets: []
    };

    let options = {
      responsive: false,
      legend: {
        display: true
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0,
            max: 100
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
    this.chart.data= {labels: this.props.labels, datasets: this.props.datasets}
    this.chart.options.legend.display = this.props.legend;
    this.chart.update();
  }

  render() {
    return (
      <canvas id='term_marks' style={{display: 'inline-flex', width: 'auto', height: 500, margin: '10px'}}></canvas>
    );
  }
}

