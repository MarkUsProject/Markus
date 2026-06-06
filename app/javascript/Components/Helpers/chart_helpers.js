export function chartScales(xTitle = I18n.t("main.grade"), yTitle = I18n.t("main.frequency")) {
  let bars = document.documentElement.style.getPropertyValue("--primary_one");
  let ticksColor = document.documentElement.style.getPropertyValue("--line");
  let labelColor = document.documentElement.style.getPropertyValue("--line");
  let gridLineColor = document.documentElement.style.getPropertyValue("--gridline");
  return {
    x: {
      grid: {
        border: {color: bars},
        color: gridLineColor,
      },
      title: {
        display: true,
        text: xTitle,
        color: labelColor,
      },
      min: 0,
      max: 100,
      ticks: {
        autoSkip: false,
        color: ticksColor,
      },
    },
    y: {
      grid: {
        border: {color: bars},
        color: gridLineColor,
      },
      title: {
        display: true,
        text: yTitle,
        color: labelColor,
      },
      ticks: {
        color: ticksColor,
      },
    },
  };
}
