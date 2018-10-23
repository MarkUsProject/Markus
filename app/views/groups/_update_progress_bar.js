function update_bar(score, outof) {
  var width = outof <= 0 ? 100 : (score/outof) * 100;
  var $bar = $('.progress_span');
  $bar.text(`${score}/${outof} ${I18n.t('results.state.complete')}`);
  $bar.css('width', width + '%');
  if (width > 75) {
    $bar.css('background-color', 'green')
  } else if (width > 35) {
    $bar.css('background-color', '#FBC02D')
  }
}
