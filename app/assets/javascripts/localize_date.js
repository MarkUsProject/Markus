/** Convert a date/time to a nice Date object.
    Example: 2014-08-21 14:38:00 UTC -> [Date object] */
function convert_date_time(date) {
  var arr_date = date.split(/[ T]/);
  var iso_date = arr_date[0] + ' ' + arr_date[1] + arr_date[2];
  return moment(iso_date);
}

/** Localize the date with a specified locale format string. */
function localize_date(actual_date_div, date_div, format) {
  if (actual_date_div.value !== '') {
    var date = moment(actual_date_div.value);
    date_div.value = date.format(format);
  }
}

/** Localize the date/time with a specified locale format string. */
function localize_datetime(actual_date_div, date_div, format) {
  if (actual_date_div.value.indexOf(' ') > -1) {
    var date = convert_date_time(jQuery(actual_date_div).attr('value'));
    date_div.value = date.format(format);
  }
}
