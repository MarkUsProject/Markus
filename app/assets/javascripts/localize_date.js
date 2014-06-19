/** Get the time zone offset (from UTC) in hours.
    Examples: -4, +6.5, etc. */
function get_timezone_offset() {
  var offset = new Date().getTimezoneOffset() / 60;
  return (offset < 0 ? '' : '-') + offset;
}

/** Convert a date to a nice Date object with the offset.
    Example: 2014-08-21 -> [Date object] */
function convert_date(date) {
  var iso_date = date + 'T00:00';
  return moment(iso_date).add('hours', get_timezone_offset());
}

/** Convert a date/time to a nice Date object with the offset.
    Example: 2014-08-21 14:38:00 UTC -> [Date object] */
function convert_date_time(date) {
  var arr_date = date.split(' ');
  iso_date = arr_date[0] + 'T' + arr_date[1];
  return moment(iso_date).add('hours', get_timezone_offset());
}

/** Localize the date with a specified locale format string, taking into
    account the time zone offset. */
function localize_date(actual_date_div, date_div, format) {
  if (actual_date_div.value !== '') {
    var date = convert_date(actual_date_div.value);
    date_div.value = date.toString(format);
  }
}

/** Localize the date/time with a specified locale format string, taking into
    account the time zone offset. */
function localize_datetime(actual_date_div, date_div, format) {
  if (actual_date_div.value.indexOf(' ') > -1) {
    var date = convert_date_time(actual_date_div.value);
    date_div.value = date.format(format);
  }
}
