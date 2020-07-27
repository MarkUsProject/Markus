// Requires Chart.js to have been loaded.
Chart.defaults.global.defaultColor = 'rgba(151,187,205,0.5)';
Chart.defaults.global.elements.rectangle.backgroundColor = 'rgba(151,187,205,0.5)';
Chart.defaults.global.elements.rectangle.borderColor = 'rgba(151,187,205,0.5)';

Chart.defaults.bar.scales.yAxes = [{
  ticks: {
    beginAtZero: true
  }
}];

Chart.defaults.global.legend.display = false;

Chart.defaults.datasets = [{
  barPercentage: 0.9,
  categoryPercentage: 0.8
}];
