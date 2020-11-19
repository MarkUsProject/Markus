// Requires Chart.js to have been loaded.
$(document).ready(function () {
  let bars = document.documentElement.style.getPropertyValue('--primary_one');
  let ticksColor = document.documentElement.style.getPropertyValue('--line');
  let labelColor = document.documentElement.style.getPropertyValue('--line');
  let gridLineColor = document.documentElement.style.getPropertyValue('--primary_three');

  Chart.defaults.global.defaultColor = bars;
  Chart.defaults.global.defaultFontColor = labelColor;
  Chart.defaults.global.elements.rectangle.backgroundColor = bars;
  Chart.defaults.global.elements.rectangle.borderColor = bars;

  Chart.defaults.bar.scales.yAxes = [{
    gridLines: {
      color: gridLineColor
    },
    ticks: {
      beginAtZero: true,
      fontColor: ticksColor
    }
  }];

  Chart.defaults.global.type = 'bar';

  Chart.defaults.bar.scales.xAxes = [{
    ticks: {
      type: 'linear',
      fontColor: ticksColor,

    },
    gridLines: {
      color: gridLineColor,
      offsetGridLines: true
    },
    offset: true
  }];

  Chart.defaults.global.legend.display = false;
  Chart.defaults.global.legend.labels.fontColor = labelColor;

  Chart.defaults.datasets = [{
    barPercentage: 0.9,
    categoryPercentage: 0.8
  }];
});
