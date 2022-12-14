import flatpickr from "flatpickr";
import {I18n} from "i18n-js";
import translations from "translations.json";

const i18n = new I18n(translations);

const FLATPICKR_LOCALE = {
  hourAriaLabel: i18n.t("datetime.prompts.hour"),
  minuteAriaLabel: i18n.t("datetime.prompts.minute"),
  months: {
    longhand: i18n.t("date.month_names").slice(1),
    shorthand: i18n.t("date.abbr_month_names").slice(1),
  },
  weekdays: {
    longhand: i18n.t("date.day_names"),
    shorthand: i18n.t("date.abbr_day_names"),
  },
};

flatpickr.setDefaults({
  locale: FLATPICKR_LOCALE,
  allowInput: true,
  enableTime: true,
  showMonths: 2,
  dateFormat: i18n.t("time.format_string.flatpickr"),
});
