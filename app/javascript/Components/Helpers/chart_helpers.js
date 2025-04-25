export function chartScales() {
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
        text: I18n.t("main.grade"),
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
        text: I18n.t("main.frequency"),
        color: labelColor,
      },
      ticks: {
        color: ticksColor,
      },
    },
  };
}
