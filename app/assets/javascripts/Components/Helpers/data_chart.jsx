import React from 'react';

export class DataChart extends React.Component {
  componentDidMount() {
    this.setChart()
  }

  setChart() {
    let ctx = document.getElementById('term_marks').getContext('2d');


    let data = {
      labels: ['January', 'February', 'March', 'April', 'May', 'June', 'July'],
      datasets: [{
        label: 'My First dataset',
        backgroundColor: '#ffb4b4',
        data: [0, 10, 5, 2, 20, 30, 45]
      }, {
        label: 'My Second dataset',
        backgroundColor: '#89b1dd',
        data: [4, 14, 9, 4, 20, 34, 40]
      }]
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

