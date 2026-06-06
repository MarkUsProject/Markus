// Open the keyboard shortcuts help modal
import Mousetrap from "mousetrap";

// Allow navigation keybindings to fire even when a form input has focus.
// Mousetrap suppresses all bindings on inputs by default to avoid interfering
// with typing, but these combos don't produce characters so suppression is wrong.
// shift+n is intentionally excluded so it stays blocked while typing.
const _originalStopCallback = Mousetrap.prototype.stopCallback;
Mousetrap.prototype.stopCallback = function (e, element, combo) {
  const allowedOnInputs = [
    "shift+up",
    "shift+down",
    "shift+left",
    "shift+right",
    "ctrl+shift+right",
    "alt+enter",
  ];
  if (allowedOnInputs.includes(combo)) return false;
  return _originalStopCallback.call(this, e, element, combo);
};

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
