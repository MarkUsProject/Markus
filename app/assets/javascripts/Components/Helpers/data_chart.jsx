import React from 'react';

export class DataChart extends React.Component {

  setChart(info) {
    let ctx = document.getElementById('term_marks').getContext('2d');
    console.log(info);
    let data = {
      labels: info.labels,
      datasets: [{data: info.marks}]
    };
    var options = {
      responsive: true,
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

    // Draw it
    new Chart(ctx, {
      type: 'bar',
      data: data,
      options: options
    });
  }

  render() {
    return (
      <canvas id='term_marks' width='500px' height='450px'></canvas>
    );
  }
}

