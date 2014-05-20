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

      var language = document.getElementById("locale").value;
      if (language.indexOf('fr') >= 0) {
        /* French locale */
        from_time_node.update(from_time.toLocale('fr'));
        to_time_node.update(to_time.toLocale('fr'));
      } else if (language.indexOf('pt') >= 0) {
        /* Portuguese locale */
        from_time_node.update(from_time.toLocale('pt'));
        to_time_node.update(to_time.toLocale('pt'));
      } else {
        /* English locale, or something else: no need to change */
        from_time_node.update(from_time.toLocaleString());
        to_time_node.update(to_time.toLocaleString());
      }

      current_time = to_time;
    });
  },
  set_due_date: function(new_due_date) {
    delete this.due_date;
    this.due_date = (typeof new_due_date == 'undefined' ?
                     new Date() : new Date(Date.parseFormattedString(new_due_date)));
  },
  set_or_default: function(value, default_value) {
    if (typeof value == 'undefined') {
      return default_value;
    }
    return value;
  }
});

Date.prototype.toLocale = function(locale) {
  if (locale == 'fr') {
    var months = ["janvier", "février", "mars", "avril", "mai", "juin", "juillet", "août", "septembre", "octobre", "novembre", "décembre"];
    return pad(this.getDate()) + " " + months[this.getMonth()] + " " + this.getFullYear() + ", " +
           pad(this.getHours()) + ":" + pad(this.getMinutes()) + ":" + pad(this.getSeconds());
  } else if (locale == 'pt') {
    var months = ["janeiro", "fevereiro", "março", "abril", "maio", "junho", "julho", "agosto", "setembro", "outubro", "novembro", "dezembro"];
    return pad(this.getDate()) + " de " + months[this.getMonth()] + " de " + this.getFullYear() + ", " +
           pad(this.getHours()) + ":" + pad(this.getMinutes()) + ":" + pad(this.getSeconds());
  }
}

function pad(number) {
  return (number < 10) ? "0" + number : number;
}
