function compare_dates(a, b) {
  function parse_date(d) {
    var dateElement = jQuery.parseHTML(d);
    return Date.parse(jQuery(dateElement[0]).text());
  }

  return compare_numeric_values(parse_date(a), parse_date(b));
}

function compare_gradebox(a, b) {
  return compare_numeric_values(a.props.value, b.props.value);
}

function compare_anchor_text(a, b) {
  function parse_anchor(a) {
    var is_anchor = a.indexOf('<a') >= 0;
    if (is_anchor) {
      var open_tag_end = a.indexOf('>', a.indexOf('<a'));
      var close_tag_start = a.indexOf('</a', open_tag_end + 1);
    } else {
      var open_tag_end = a.indexOf('>', a.indexOf('<span'));
      var close_tag_start = a.indexOf('</span', open_tag_end + 1);
    }
    if (open_tag_end !== -1 && close_tag_start !== -1) {
      return a.substring(open_tag_end + 1, close_tag_start);
    }
    return a;
  }

  return compare_values(parse_anchor(a), parse_anchor(b));
}

function compare_fractions(a, b) {
  function parse_fraction(f) {
    var slash = f.indexOf('/');
    if (slash !== -1) {
      var numerator = parseInt(f.substring(0, slash));
      var denominator = parseInt(f.substring(slash + 1));
      if (denominator !== 0 && isFinite(numerator) && isFinite(denominator)) {
        return numerator / denominator;
      }
    }
    return f;
  }

  return compare_numeric_values(parse_fraction(a), parse_fraction(b));
}

function compare_numeric_values(a, b) {
  if (isNaN(b) || a > b) {
    return 1;
  } else if (isNaN(a) || a < b) {
    return -1;
  }
  return 0;
}

function compare_values(a, b) {
  if (!b || a > b) {
    return 1;
  } else if (!a || a < b) {
    return -1;
  }
  return 0;
}
