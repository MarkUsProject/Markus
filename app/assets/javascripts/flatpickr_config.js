$(document).ready(function () {
  const FlatpickrLocale = {
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

  const FlatpickrConfig = {
    locale: FlatpickrLocale,
    allowInput: true,
    enableTime: true,
    showMonths: 2,
    dateFormat: I18n.t("date.format_string.date_and_time"),
  };

  Flatpickr.setDefaults(FlatpickrConfig);
});
