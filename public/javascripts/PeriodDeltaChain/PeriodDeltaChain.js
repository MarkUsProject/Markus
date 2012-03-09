/** PeriodLister Class

Rules:
- This class requires/assumes the Prototype javascript library
**/

var PeriodDeltaChain = Class.create({
 
  initialize: function(params) {
    if (Date.parseFormattedString == null || Date.parseFormattedString == undefined) {
      throw("Expected Date.prototype.parseFormattedString implemented.  See CalendarDateSelect plugin for Rails");
    }
    this.hour = 3600000; // 1 hour is 3600000 milliseconds
    this.period_root_id = params.period_root_id;
    this.date_format = this.set_or_default(params.date_format, "");
    this.set_due_date(params.due_date);
    this.period_class = this.set_or_default(params.period_class, 'period');
  },
  refresh: function() {
    var me = this;
    var current_time = new Date(this.due_date);
    $$('#' + this.period_root_id + ' .' + this.period_class).each(function(node) {
      var from_time_node = node.down('.PeriodDeltaChain_FromTime');
      var to_time_node = node.down('.PeriodDeltaChain_ToTime');
      var hours_value = node.down('.PeriodDeltaChain_Hours').getValue();
      var from_time = new Date(current_time);
      var to_time = new Date(current_time);
      to_time.setTime(to_time.getTime() + (me.hour * hours_value));
      
      from_time_node.update(from_time.toDateString() + ' ' + from_time.toLocaleTimeString());
      to_time_node.update(to_time.toDateString() + ' ' + to_time.toLocaleTimeString());

      current_time = to_time;

    });
  },
  set_due_date: function(new_due_date) {
    delete this.due_date;
    this.due_date = (typeof new_due_date == 'undefined' ?
                     new Date(Date.parseFormattedString(new_due_date)) : new Date());
  },
  set_or_default: function(value, default_value) {
    if (typeof value == 'undefined') {
      return default_value;
    }
    return value;
  }
});
