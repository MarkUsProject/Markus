import React from 'react';
import {render} from 'react-dom';
import { Bar } from 'react-chartjs-2';

export class DataChart extends React.Component {

  render() {
    let options = {
      responsive: false,
      legend: {
        display: this.props.legend
      },
      scales: {
        y: {
          gridLines: {
            color: document.documentElement.style.getPropertyValue('--gridline')
          },
          ticks: {
            beginAtZero: true,
            min: 0,
            max: 100
          },
          scaleLabel: {
            display: true,
            labelString: this.props.yTitle
          }
        },
        x: {
          gridLines: {
            offsetGridLines: true,
            color: document.documentElement.style.getPropertyValue('--gridline')
          },
          scaleLabel: {
            display: true,
            labelString: this.props.xTitle
          },
          offset: true
        }
      }
    };

    return (
        <Bar data={this.props} options={options} width={this.props.width} height={500} margin={'10px'} display={'inline-flex'} id={'term_marks'}/>
    );
  }
}

export function makeDataChart(elem, props) {
  render(<DataChart {...props} />, elem);
}
