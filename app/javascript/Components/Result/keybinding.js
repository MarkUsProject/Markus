// Open the keyboard shortcuts help modal
import Mousetrap from "mousetrap";

export function bind_keybindings() {
  Mousetrap.bind("?", function () {
    modal_help.open();
  });

  function is_text_selected() {
    return "getSelection" in window && window.getSelection().type === "Range";
  }

  // Go to the previous submission with <
  Mousetrap.bind("shift+left", function () {
    // Don't override range selection keybindings
    if (!is_text_selected()) {
      $(".button.previous")[0].click();
    }
  });

  // Go to next submission with >
  Mousetrap.bind("shift+right", function () {
    if (!is_text_selected()) {
      $(".button.next")[0].click();
    }
  });

  // Go to a random incomplete submission with ctrl + shift + right
  Mousetrap.bind("ctrl+shift+right", function () {
    // Don't override range selection keybindings
    if (!is_text_selected()) {
      $(".button.random-incomplete-submission")[0].click();
    }
  });

  // Press shift+n for new annotation modal to appear
  Mousetrap.bind("shift+n", () => {
    if ($("#annotation_dialog:visible").length == 0) {
      resultComponent.current.newAnnotation();
      return false;
    }
  });

  // When alt+enter is pressed, toggle fullscreen mode
  Mousetrap.bind("alt+enter", () => {
    resultComponent.current.toggleFullscreen();
  });
}

export function unbind_all_keybindings() {
  Mousetrap.reset();
}
