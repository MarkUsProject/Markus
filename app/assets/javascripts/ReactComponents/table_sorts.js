function parse_date(d) {
  var close_tag_end = d.lastIndexOf('>');
  if (close_tag_end !== -1) {
    return Date.parse(d.substring(close_tag_end + 1));
  }
  return Date.parse(d);
}

function compare_commit_dates(a, b) {
  var a_parsed = parse_date(
      a['commit_date'].props.dangerouslySetInnerHTML.__html.toString());
  var b_parsed = parse_date(
      b['commit_date'].props.dangerouslySetInnerHTML.__html.toString());
  if (isNaN(b_parsed) || a_parsed > b_parsed) {
    return 1;
  } else if (isNaN(a_parsed) || a_parsed < b_parsed) {
    return -1;
  }
  return 0;
}

function parse_anchor(a) {
  var open_tag_end = a.indexOf('>', a.indexOf('<a'));
  var close_tag_start = a.indexOf('</a', open_tag_end + 1);
  if (open_tag_end !== -1 && close_tag_start !== -1) {
    return a.substring(open_tag_end + 1, close_tag_start);
  }
  return a;
}

function compare_group_names(a, b) {
  var a_parsed = parse_anchor(
      a['group_name'].props.dangerouslySetInnerHTML.__html.toString());
  var b_parsed = parse_anchor(
      b['group_name'].props.dangerouslySetInnerHTML.__html.toString());
  if (a_parsed > b_parsed) {
    return 1;
  } else if (a_parsed < b_parsed) {
    return -1;
  }
  return 0;
}

function compare_repo_names(a, b) {
  var a_parsed = parse_anchor(
      a['repository'].props.dangerouslySetInnerHTML.__html.toString());
  var b_parsed = parse_anchor(
      b['repository'].props.dangerouslySetInnerHTML.__html.toString());
  if (a_parsed > b_parsed) {
    return 1;
  } else if (a_parsed < b_parsed) {
    return -1;
  }
  return 0;
}

function compare_grace_credits(a, b) {
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

  var a_parsed = parse_fraction(a['grace_credits']);
  var b_parsed = parse_fraction(b['grace_credits']);
  if (isNaN(b_parsed) || a_parsed > b_parsed) {
    return 1;
  } else if (isNaN(a_parsed) || a_parsed < b_parsed) {
    return -1;
  }
  return 0;
}
