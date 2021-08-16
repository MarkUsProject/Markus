import React from 'react';
import {render} from 'react-dom';
import { Bar } from 'react-chartjs-2';

export class DataChart extends React.Component {
  static defaultProps = {
    legend: true,
    width: 'auto',
    height: 500
  };

  render() {
    let options = {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        legend: {
          display: this.props.legend
        },
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
        <Bar
          id={'term_marks'}
          data={this.props}
          options={options}
          width={this.props.width}
          height={this.props.height}
          style={{display: 'inline-flex', margin: '10px'}}/>
    );
  }
}

export function makeDataChart(elem, props) {
  render(<DataChart {...props} />, elem);
}
