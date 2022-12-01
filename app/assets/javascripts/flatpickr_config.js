import flatpickr from "flatpickr";
import * as I18n from "i18n-js";
import "translations";

const FLATPICKR_LOCALE = {
  hourAriaLabel: I18n.t("datetime.prompts.hour"),
  minuteAriaLabel: I18n.t("datetime.prompts.minute"),
  months: {
    longhand: I18n.t("date.month_names").slice(1),
    shorthand: I18n.t("date.abbr_month_names").slice(1),
  },
  weekdays: {
    longhand: I18n.t("date.day_names"),
    shorthand: I18n.t("date.abbr_day_names"),
  },
};

flatpickr.setDefaults({
  locale: FLATPICKR_LOCALE,
  allowInput: true,
  enableTime: true,
  showMonths: 2,
  dateFormat: I18n.t("time.format_string.flatpickr"),
});
