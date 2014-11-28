function compare_commit_dates(a, b) {
  function parse_date(d) {
    var d_str =
        d['commit_date'].props.dangerouslySetInnerHTML.__html.toString();
    var close_tag_end = d_str.lastIndexOf('>');
    if(close_tag_end !== -1) {
      d_str = d_str.substring(close_tag_end + 1);
    }
    return Date.parse(d_str);
  }
  var a_parsed = parse_date(a);
  var b_parsed = parse_date(b);
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
  return (open_tag_end !== -1 && close_tag_start !== -1) ?
      a.substring(open_tag_end + 1, close_tag_start) : a;
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
