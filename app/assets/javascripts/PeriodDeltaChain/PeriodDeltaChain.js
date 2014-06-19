/** PeriodLister Class */

var PeriodDeltaChain = Class.create({
  initialize: function(params) {
    this.hour = 3600000; // 1 hour is 3600000 milliseconds
    this.period_root_id = params.period_root_id;
    this.date_format = this.set_or_default(params.date_format, '');
    this.set_due_date(params.due_date);
    this.period_class = this.set_or_default(params.period_class, 'period');
  },
  refresh: function() {
    var hour = this.hour;
    var current_time = new Date(this.due_date);
    jQuery('#' + this.period_root_id + ' .' + this.period_class).each(function() {
      var from_time_node = this.querySelector('.PeriodDeltaChain_FromTime');
      var to_time_node   = this.querySelector('.PeriodDeltaChain_ToTime');
      var hours_value    = this.querySelector('.PeriodDeltaChain_Hours').value;
      var from_time = new Date(current_time);
      var to_time   = new Date(current_time);
      to_time.setTime(to_time.getTime() + (hour * hours_value));

      var language = document.getElementById('locale').value;
      var options = { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric',
                      hour: 'numeric', minute: 'numeric' };

      from_time_node.update(from_time.toLocaleString(language, options));
      to_time_node.update(to_time.toLocaleString(language, options));

      current_time = to_time;
    });
  },
  set_due_date: function(new_due_date) {
    delete this.due_date;
    // this.due_date = new Date(convert_date(new_due_date));
  },
  set_or_default: function(value, default_value) {
    if (typeof value == 'undefined') {
      return default_value;
    }
    return value;
  }
});


/** Converts date string to a format that the Date prototype likes. */
function convert_date(due_date) {
  // Only convert if not in the right format, i.e "2014-01-01 00:00"
  if (due_date.indexOf(' ') > -1) {
    // Right format, i.e. "2014-01-01T00:00+00:00"
    var arr_date = due_date.split(' ');
    return arr_date[0] + 'T' + arr_date[1] + '+00:00';
  }
  return due_date;
}
