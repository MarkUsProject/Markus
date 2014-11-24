function compare_commit_dates(a, b) {
  function parse_date(d) {
    var d_str =
        d['commit_date'].props.dangerouslySetInnerHTML.__html.toString();
    var tag_end_pos = d_str.lastIndexOf('>');
    if(tag_end_pos != -1)
      d_str = d_str.substring(tag_end_pos + 1);
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