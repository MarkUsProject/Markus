function hideMenu() {
  var body_classes = document.body.classList;
  if (body_classes.contains('show_menu')) {
    body_classes.remove('show_menu');
  }
}

function initMenu() {
  /* Menu toggle for mobile views */
  document.getElementById('mobile_menu').addEventListener('click', function() {
    var body_classes = document.body.classList;

    if (body_classes.contains('show_menu')) {
      body_classes.remove('show_menu');
    } else {
      body_classes.add('show_menu');
    }
  }, false);

  /* Close menu if content clicked, or if window resized and no longer "mobile" */
  document.getElementById('content').addEventListener('click', hideMenu, false);

  window.onresize = function() {
    if (window.innerWidth > 500) { hideMenu(); }
  }
}

window.onload = initMenu;
