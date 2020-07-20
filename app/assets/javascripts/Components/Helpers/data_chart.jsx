import React from 'react';

export class DataChart extends React.Component {

  setChart(info, legend) {
    // info is list with first element as labels, each subsequent item a dataset
    let ctx = document.getElementById('term_marks').getContext('2d');
    let data = {
      labels: info[0],
      datasets: info.slice(1)
    };
    var options = {
      responsive: false,
      legend: {
        display: legend
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

    new Chart(ctx, {
      type: 'bar',
      data: data,
      options: options
    });
  }

  render() {
    return (
      <canvas id='term_marks' style={{display: 'inline-flex', width: 'auto', height: 500, margin: '10px'}}></canvas>
    );
  }
}

