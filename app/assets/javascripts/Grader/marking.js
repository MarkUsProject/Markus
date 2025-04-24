(function () {
  const domContentLoadedCB = function () {
    // Handle indenting in the new annotation textarea (2 spaces)
    $("#new_annotation_content").keydown(function (e) {
      var keyCode = e.keyCode || e.which;

      if (keyCode == 9) {
        e.preventDefault();
        var start = this.selectionStart;
        var end = this.selectionEnd;

        // Add the 2 spaces
        this.value = this.value.substring(0, start) + "  " + this.value.substring(end);

        // Put caret in correct position
        this.selectionStart = this.selectionEnd = start + 2;
      }
    });
  };

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", domContentLoadedCB);
  } else {
    domContentLoadedCB();
  }
})();

// designate $next_criteria as the currently selected criteria
function activeCriterion($next_criteria) {
  if (!$next_criteria.hasClass("active-criterion")) {
    const $criteria_list = $(".marks-list > li");
    // remove all previous active-criterion (there should only be one)
    $criteria_list.removeClass("active-criterion");
    // scroll the $next_criteria to the top of the criterion bar
    $("#mark_viewer").animate(
      {
        scrollTop: $next_criteria.offset().top - $criteria_list.first().offset().top,
      },
      100
    );
    $next_criteria.addClass("active-criterion");
    // Unfocus any exisiting textfields/radio buttons
    $(".flexible_criterion input, .checkbox_criterion input").blur();
    // Remove any active rubrics
    $(".active-rubric").removeClass("active-rubric");
    if ($next_criteria.hasClass("flexible_criterion")) {
      var $input = $next_criteria.find('input[type="text"]');
      // This step is necessary for focusing the cursor at the end of input
      $input.focus().val($input.val());
    } else if ($next_criteria.hasClass("rubric_criterion")) {
      $selected = $next_criteria.find(".rubric-level.selected");
      if ($selected.length) {
        $selected.addClass("active-rubric");
      } else {
        $next_criteria.find("tr>td")[0].addClass("active-rubric");
      }
    } else if ($next_criteria.hasClass("checkbox_criterion")) {
      $selected_option = $next_criteria.find("input[checked]")[0];
      if ($selected_option) {
        $selected_option.focus();
      } else {
        $next_criteria.find("input")[0].focus();
      }
    }
    // If this current criteria is not expanded, expand it
    if (!$next_criteria.hasClass("expanded")) {
      if ($next_criteria.hasClass("rubric_criterion")) {
        $next_criteria.children(".criterion_title").click();
      } else {
        $next_criteria.find(".criterion_expand").click();
      }
    }
  }
}

// Set the active-criterion to the next sibling
function nextCriterion() {
  $next_criterion = $(".active-criterion").next("li:not(.unassigned)");
  // If no next criterion exists, loop back to the first one
  if (!$next_criterion.length) {
    $next_criterion = $(".marks-list > li:not(.unassigned)").first();
  }
  activeCriterion($next_criterion);
}

// Set the active-criterion to the previous sibling
function prevCriterion() {
  $prev_criterion = $(".active-criterion").prev("li:not(.unassigned)");
  // If no previous criterion exists, loop back to the last one
  if (!$prev_criterion.length) {
    $prev_criterion = $(".marks-list > li:not(.unassigned)").last();
  }
  activeCriterion($prev_criterion);
}
