function hideMenu() {
  document.body.classList.remove("show_menu");
}

function initMenu() {
  /* Menu toggle for mobile views */
  document.getElementById("mobile_menu").addEventListener(
    "click",
    () => {
      document.body.classList.toggle("show_menu");
    },
    false
  );

  /* Close menu if content clicked, or if window resized and no longer "mobile" */
  document.getElementById("content").addEventListener(
    "click",
    event => {
      // Prevent accidental clicks on links or something; just close the menu
      if (document.body.classList.contains("show_menu")) {
        event.preventDefault();
      }

      hideMenu();
    },
    false
  );

  window.onresize = () => {
    if (window.innerWidth > 500) {
      hideMenu();
    }
  };
}
// using addEventListener as opposed to direct assignment so that event listeners added elsewhere
// don't get overridden
window.addEventListener("DOMContentLoaded", () => {
  initMenu();
});
