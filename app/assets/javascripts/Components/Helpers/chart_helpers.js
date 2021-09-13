import * as I18n from "i18n-js";

export const chartScales = {
  x: {
    title: {
      display: true,
      text: I18n.t("main.grade"),
    },
    min: 0,
    max: 100,
    ticks: {autoSkip: false},
  },
  y: {
    title: {
      display: true,
      text: I18n.t("main.frequency"),
    },
  },
};
