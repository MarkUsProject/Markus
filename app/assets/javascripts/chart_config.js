// Requires Chart.js to have been loaded.
Chart.defaults.global.defaultColor = 'rgba(151,187,205,0.5)';
Chart.defaults.global.elements.rectangle.backgroundColor = 'rgba(151,187,205,0.5)';
Chart.defaults.global.elements.rectangle.borderColor = 'rgba(151,187,205,0.5)';

Chart.defaults.bar.scales.xAxes = [{
  type: 'category',

  categoryPercentage: 0.8,
  barPercentage: 0.9,

  // grid line settings
  gridLines: {
    offsetGridLines: true,
  },
  ticks: {
    maxRotation: 0,
    autoSkip: false
  }
}];

Chart.defaults.bar.scales.yAxes = [{
  ticks: {
    beginAtZero: true
  }
}];

Chart.defaults.global.legend.display = false;
