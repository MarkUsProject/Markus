/** PeriodLister Class */

function PeriodDeltaChain(params) {
  this.period_root_id = params.period_root_id;
  this.date_format = this.set_or_default(params.date_format, '');
  this.set_due_date(params.due_date);
  this.period_class = this.set_or_default(params.period_class, 'period');
}

PeriodDeltaChain.prototype.refresh = function() {
  var current_time = this.due_date;
  var format       = this.date_format;
  var period_selector = '#' + this.period_root_id + ' .' + this.period_class;
  var me = this;

  jQuery(period_selector).each(function() {
    var from_time_node = this.querySelector('.PeriodDeltaChain_FromTime');
    var to_time_node   = this.querySelector('.PeriodDeltaChain_ToTime');
    var hours_value    = this.querySelector('.PeriodDeltaChain_Hours').value;
    var from_time = moment(current_time, me.date_format);
    var to_time   = moment(current_time, me.date_format);

    jQuery(from_time_node).html(from_time.format(format));
    jQuery(to_time_node).html(to_time.add('hours', hours_value).format(format));

    current_time = to_time;
  });

  if (jQuery(period_selector).length < 2) {
    jQuery(period_selector + ' a').hide();
  } else {
    jQuery(period_selector + ' a').show();
  }
}

PeriodDeltaChain.prototype.set_due_date = function(new_due_date) {
  delete this.due_date;
  this.due_date = convert_date(new_due_date);
}

PeriodDeltaChain.prototype.set_or_default = function(value, default_value) {
  if (typeof value == 'undefined') {
    return default_value;
  }
  return value;
}


/** Converts date string to an actual Date object. */
function convert_date(due_date) {
  if (due_date.indexOf(' ') > -1) {
    var arr_date = due_date.split(/[ T]/).filter(function (s) {
      return s !== '';
    });
    due_date = arr_date[0] + ' ' + arr_date[1] + ' ' + arr_date[2];
  }
  return due_date;
}
