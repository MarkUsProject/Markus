// this component is a wrapper around the jqueryUI datepicker

import React from 'react';

class Datepicker extends React.Component {

  constructor(props) {
    super(props);
    this.state = {
      date: props.initial_date,
      disabled: props.disabled || false,
      warn_before_now: props.warn_before_now || false
    }
  };

  onChange = (date) => {
    this.setState({date: date});
    if (typeof this.props.onChange === "function") {
      this.props.onChange(date)
    }
  };

  setDate = (date) => {
    this.onChange(date)
  };

  checkStartDate = () => {
    if (this.props.warn_before_now && moment(this.state.date, I18n.t('time.format_string.js')).isBefore(moment())) {
      alert(I18n.t('past_start_date_edit_warning'));
    }
  };

  setDisabled = (disabled) => {
    this.setState({disabled: disabled})
  };

  componentDidMount() {
    $('.datepicker').datetimepicker({
      controlType:      this.props.controlType || 'select',
      showTime:         this.props.showTime || false,
      numberOfMonths:   this.props.numberOfMonths || 2,
      secondMax:        this.props.secondMax || 0,
      onSelect:         this.onChange,
      onClose:          this.props.onClose || this.checkStartDate,
      dateFormat:       this.props.dateFormat || I18n.t('date.format_string.datetimepicker'),
      timeFormat:       this.props.timeFormat || I18n.t('time.format_string.time_only'),
      showTimezone:     this.props.showTimezone || false,
      monthNames:       this.props.monthNames || I18n.t('date.month_names').slice(1), // Drop first null element
      dayNames:         this.props.dayNames || I18n.t('date.day_names'),
      dayNamesMin:      this.props.dayNamesMin || I18n.t('date.abbr_day_names'),
      hourText:         this.props.hourText || I18n.t('datetime.prompts.hour'),
      minuteText:       this.props.minuteText || I18n.t('datetime.prompts.minute'),
      timeText:         this.props.timeText || I18n.t('datetime.prompts.time'),
      prevText:         this.props.prevText || I18n.t('time.prev'),
      nextText:         this.props.nextText || I18n.t('time.next'),
      closeText:        this.props.closeText || I18n.t('close')
    });
  }

  render() {
    return (
      <input
        type='text'
        className='datepicker'
        value={this.state.date}
        onChange={function () {}} //dummy function to make input writeable
                                  // (onchange is handled by the datepickers onSelect method)
        disabled={this.state.disabled}
      />
    )
  }
}

export default Datepicker;
