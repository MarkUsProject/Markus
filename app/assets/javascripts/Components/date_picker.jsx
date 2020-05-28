// this component is a wrapper around the jqueryUI datepicker

import React from 'react';

class Datepicker extends React.Component {

  static defaultProps = {
    controlType: 'select',
    showTime: false,
    numberOfMonths: 2,
    secondMax: 0,
    showTimezone: false,
  };

  handleClose = () => {
    if (this.props.warn_before_now && moment(this.props.date, I18n.t('time.format_string.js')).isBefore(moment())) {
      alert(I18n.t('date.before_now_warning'));
    }
    if (typeof this.props.onClose === 'function') {
      this.props.onClose();
    }
  };

  handleSelect = (date) => {
    if (typeof this.props.onChange === 'function') {
      this.props.onChange(date);
    }
  };

  componentDidMount() {
    $('.datepicker').datetimepicker({
      controlType:      this.props.controlType,
      showTime:         this.props.showTime,
      numberOfMonths:   this.props.numberOfMonths,
      secondMax:        this.props.secondMax,
      onSelect:         this.handleSelect,
      onClose:          this.handleClose,
      showTimezone:     this.props.showTimezone,
      dateFormat: typeof this.props.dateFormat === 'undefined' ? I18n.t('date.format_string.datetimepicker') : this.props.dateFormat,
      timeFormat: typeof this.props.timeFormat === 'undefined' ? I18n.t('time.format_string.time_only') : this.props.timeFormat,
      monthNames: typeof this.props.monthNames === 'undefined' ? I18n.t('date.month_names').slice(1) : this.props.monthNames,
      dayNames: typeof this.props.dayNames === 'undefined' ? I18n.t('date.day_names') : this.props.dayNames,
      dayNamesMin: typeof this.props.dayNamesMin === 'undefined' ? I18n.t('date.abbr_day_names') : this.props.dayNamesMin,
      hourText: typeof this.props.hourText === 'undefined' ? I18n.t('datetime.prompts.hour') : this.props.hourText,
      minuteText: typeof this.props.minuteText === 'undefined' ? I18n.t('datetime.prompts.minute') : this.props.minuteText,
      timeText: typeof this.props.timeText === 'undefined' ? I18n.t('time.time') : this.props.timeText,
      prevText: typeof this.props.prevText === 'undefined' ? I18n.t('time.prev') : this.props.prevText,
      nextText: typeof this.props.nextText === 'undefined' ? I18n.t('time.next') : this.props.nextText,
      closeText: typeof this.props.closeText === 'undefined' ? I18n.t('close') : this.props.closeText
    });
  }

  render() {
    return (
      <input
        type='text'
        className='datepicker'
        value={this.props.date}
        onChange={function () {}} //dummy function to make input writeable
                                  // (onchange is handled by the datepickers onSelect method)
        disabled={this.props.disabled}
      />
    )
  }
}

export default Datepicker;
