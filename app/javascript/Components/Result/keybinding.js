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

  // Go to the previous criterion with shift + up
  Mousetrap.bind("shift+up", function (e) {
    if (!is_text_selected()) {
      e.preventDefault();
      window.prevCriterion();
      return false;
    }
  });

  // Go to the next criterion with shift + down
  Mousetrap.bind("shift+down", function (e) {
    if (!is_text_selected()) {
      e.preventDefault();
      window.nextCriterion();
      return false;
    }
  });

  // When on rubric criterion, use the arrow keys to hover over the next rubric
  Mousetrap.bind("up", function (e) {
    let $current_criteria = $(".active-criterion");
    if (
      $current_criteria.length &&
      $current_criteria.hasClass("rubric_criterion") &&
      !$current_criteria.hasClass("unassigned")
    ) {
      e.preventDefault();
      let $selected = $(".active-rubric");
      if ($selected.length) {
        let $next = $selected.parent().prev();
        if (!$next.length) {
          // if no next element exists, loop back to the last of the list
          $next = $selected.parent().siblings().last();
        }
        $selected.removeClass("active-rubric");
        $next.children().addClass("active-rubric");
      }
      return false;
    }
  });

  // When on rubric criteria, use the arrow keys to hover over the next rubric
  Mousetrap.bind("down", function (e) {
    let $current_criteria = $(".active-criterion");
    if (
      $current_criteria.length &&
      $current_criteria.hasClass("rubric_criterion") &&
      !$current_criteria.hasClass("unassigned")
    ) {
      e.preventDefault();
      let $selected = $(".active-rubric");
      if ($selected.length) {
        let $next = $selected.parent().next();
        if (!$next.length) {
          // if no next element exists, loop back to the front of the list
          $next = $selected.parent().siblings().first();
        }
        $selected.removeClass("active-rubric");
        $next.children().addClass("active-rubric");
      }
      return false;
    }
  });

  // When enter is pressed, and there is an active rubric selected, trigger select and collapse
  Mousetrap.bind("enter", function (e) {
    if ($(".active-rubric").length) {
      e.preventDefault();
      $(".active-rubric")[0].click();
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
