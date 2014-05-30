function pad(number, length){
  var str = "" + number;
  while (str.length < length) {
    str = '0' + str;
  }
  return str;
}

function get_timezone_offset() {
  var offset = new Date().getTimezoneOffset() / 60;
  offset = ((offset < 0 ? '+' : '-') +
          pad(Math.abs(offset%60), 2) +
          pad(parseInt(Math.abs(offset/60)), 2));
  return offset;
}

/** Convert a date to the ISO 8601 format.
    Example: 2014-08-21 14:38:00 UTC -> 2014-08-27T14:38:00+0000 */
function convert_date_to_iso(date) {
  var arr_date = date.split(' ');
  return arr_date[0] + 'T' + arr_date[1] + '+0000';
}

/** Localize the date, taking into account the time zone offset. */
function localize_date(actual_date_div, date_div, language) {
  if (actual_date_div.value != '') {
    var options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' };
    var offset = get_timezone_offset();
    date_div.value = new Date(actual_date_div.value + "T00:00" + offset).toLocaleString(language, options);
  }
}

/** Convert a date in the given div to ISO 8601 format, then to a
    localized format. */
function localize_datetime(actual_date_div, date_div, language) {
  if (actual_date_div.value.indexOf('UTC') > -1) {
    var options  = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
                     hour: 'numeric', minute: 'numeric', timeZoneName: 'short' };

    var iso_date = convert_date_to_iso(actual_date_div.value);
    date_div.value = new Date(Date.parse(iso_date)).toLocaleString(language, options);
  }
}
