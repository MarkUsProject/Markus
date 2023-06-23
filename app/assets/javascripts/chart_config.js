(function () {
  // Requires Chart.js to have been loaded.
  const domContentLoadedCB = function () {
    let bars = document.documentElement.style.getPropertyValue("--primary_one");
    let ticksColor = document.documentElement.style.getPropertyValue("--line");
    let labelColor = document.documentElement.style.getPropertyValue("--line");
    let gridLineColor = document.documentElement.style.getPropertyValue("--gridline");

    Chart.defaults.color = labelColor;
    Chart.defaults.borderColor = bars;
    Chart.defaults.backgroundColor = bars;
    Chart.defaults.elements.bar.backgroundColor = bars;
    Chart.defaults.elements.bar.borderColor = bars;

    Chart.overrides.bar.scales.y = {
      grid: {
        color: gridLineColor,
      },
      beginAtZero: true,
      ticks: {
        color: ticksColor,
      },
    };

    Chart.defaults.type = "bar";

    Chart.overrides.bar.scales.x = {
      ticks: {
        type: "linear",
        color: ticksColor,
      },
      grid: {
        color: gridLineColor,
        offset: true,
      },
      offset: true,
    };

    Chart.defaults.plugins.legend.display = false;
    Chart.defaults.plugins.legend.labels.fontColor = labelColor;

    Chart.defaults.datasets.bar.barPercentage = 0.9;
    Chart.defaults.datasets.bar.categoryPercentage = 0.8;

    Chart.defaults.animation.duration = 0;
  };

  document.addEventListener("DOMContentLoaded", domContentLoadedCB);
})();
