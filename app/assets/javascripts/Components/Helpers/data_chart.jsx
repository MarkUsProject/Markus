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
        backgroundColor: 'rgb(255, 99, 132)',
        borderColor: 'rgb(255, 99, 132)',
        data: [0, 10, 5, 2, 20, 30, 45]
      }, {
        label: 'My Second dataset',
        backgroundColor: 'rgb(74,97,208)',
        borderColor: 'rgb(51,120,173)',
        data: [4, 14, 9, 4, 20, 34, 40]
      }]
    };
    var options = {
      tooltips: {
        callbacks: {
          title: function (tooltipItems) {
            var baseNum = parseInt(tooltipItems[0].xLabel);
            if (baseNum === 0) {
              return '0-5';
            }
            else {
              return (baseNum + 1) + '-' + (baseNum + 5);
            }
          }
        }
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

