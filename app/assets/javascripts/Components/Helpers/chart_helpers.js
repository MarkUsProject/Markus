import * as I18n from "i18n-js";

export const chartScales = {
  x: {
    grid: {
      borderColor: "#98c7ff", // --primary_one
      color: "#b1b1b140", // --gridline
    },
    title: {
      display: true,
      text: I18n.t("main.grade"),
      color: "#b1b1b1", // --gridline
    },
    min: 0,
    max: 100,
    ticks: {
      autoSkip: false,
      color: "#b1b1b1", // --gridline
    },
  },
  y: {
    grid: {
      borderColor: "#98c7ff", // --primary_one
      color: "#b1b1b140", // --gridline
    },
    title: {
      display: true,
      text: I18n.t("main.frequency"),
      color: "#b1b1b1", // --gridline
    },
    ticks: {
      color: "#b1b1b1", // --gridline
    },
  },
};
