function update_bar(score, outof) {
  var width = outof <= 0 ? 100 : (score/outof) * 100;
  var $bar = $('.progress-span');
  $bar.css('width', width + '%');
  if (width > 75) {
    $bar.css('background-color', 'green')
  } else if (width > 35) {
    $bar.css('background-color', '#FBC02D')
  }
}
