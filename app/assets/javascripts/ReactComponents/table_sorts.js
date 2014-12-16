function compare_dates(a, b) {
  function parse_date(d) {
    var close_tag_end = d.lastIndexOf('>');
    if (close_tag_end !== -1) {
      return Date.parse(d.substring(close_tag_end + 1));
    }
    return Date.parse(d);
  }

  return compare_numeric_values(parse_date(a), parse_date(b));
}

function compare_anchor_text(a, b) {
  function parse_anchor(a) {
    var open_tag_end = a.indexOf('>', a.indexOf('<a'));
    var close_tag_start = a.indexOf('</a', open_tag_end + 1);
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