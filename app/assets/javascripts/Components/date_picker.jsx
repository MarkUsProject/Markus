import React from "react";
import "../flatpickr_config";
class Datepicker extends React.Component {
  static defaultProps = {
    allowInput: true,
    enableTime: true,
    showMonths: 2,
  };

  handleClose = () => {
    if (
      this.props.warn_before_now &&
      moment(this.props.date, I18n.t("time.format_string.js")).isBefore(moment())
    ) {
      alert(I18n.t("date.before_now_warning"));
    }
    if (typeof this.props.onClose === "function") {
      this.props.onClose();
    }
  };

  handleSelect = (selectedDate, dateStr) => {
    if (typeof this.props.onChange === "function") {
      this.props.onChange(dateStr);
    }
  };

  componentDidMount() {
    Flatpickr(".datepicker", {
      allowInput: this.props.allowInput,
      enableTime: this.props.enableTime,
      showMonths: this.props.showMonths,
      onChange: this.handleSelect,
      onClose: this.handleClose,
      dateFormat:
        typeof this.props.dateFormat === "undefined"
          ? I18n.t("date.format_string.date_and_time")
          : this.props.dateFormat,
      months: {
        longhand:
          typeof this.props.monthnamesLong === "undefined"
            ? I18n.t("date.month_names").slice(1)
            : this.props.monthNames,
        shorthand:
          typeof this.props.monthNamesShort === "undefined"
            ? I18n.t("date.abbr_month_names").slice(1)
            : this.props.monthNamesShort,
      },
      weekdays: {
        longhand:
          typeof this.props.weekdaysLong === "undefined"
            ? I18n.t("date.day_names")
            : this.props.weekdaysLong,
        shorthand:
          typeof this.props.weekdaysShort === "undefined"
            ? I18n.t("date.abbr_day_names")
            : this.props.weekdaysShort,
      },
      hourAriaLabel:
        typeof this.props.hourAriaLabel === "undefined"
          ? I18n.t("datetime.prompts.hour")
          : this.props.hourAriaLabel,
      minuteAriaLabel:
        typeof this.props.minuteAriaLabel === "undefined"
          ? I18n.t("datetime.prompts.minute")
          : this.props.minuteAriaLabel,
    });
  }

  render() {
    return (
      <input
        type="text"
        className="datepicker"
        value={this.props.date}
        onChange={function () {}} //dummy function to make input writeable
        // (onchange is handled by the datepickers onSelect method)
        disabled={this.props.disabled}
      />
    );
  }
}

export default Datepicker;
