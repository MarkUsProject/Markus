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
  document.getElementById('content').addEventListener('click', function(event) {
    // Prevent accidental clicks on links or something; just close the menu
    if (document.body.classList.contains('show_menu')) {
      event.preventDefault();
    }

    hideMenu();
  }, false);

  window.onresize = function() {
    if (window.innerWidth > 500) { hideMenu(); }
  }
}

window.onload = initMenu;
