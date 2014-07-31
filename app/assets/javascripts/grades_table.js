jQuery(document).ready(function() {
  // Prevent the enter key from releasing grades
  preventEnterSubmit();

  // Bind the 'send data to db' event to all grade id boxes
  bindEventToGradeEntry();

  /**
   Because the page has loaded and the DOM is ready, we can't
   rely on this event to detect changes to the subtree. When we click
   'Next >' or '< Prev' we replace elements on the page instead of
   reloading the page (dom:loaded is not fired in this case). The new
   grade elements loaded when this happens have not had bindEventToGradeEntry()
   called on them, and modifying them will do nothing. So we need to detect the
   change of elements and call bindEventToGradeEntry() on the new grade boxes.
   */

  // The following from https://developer.mozilla.org/en/docs/Web/API/MutationObserver

  // DOM mutation observers for Firefox and Chrome respectively.
  MutationObserver = window.MutationObserver || window.WebKitMutationObserver;

  // select the target node, which is 'content' in our case. This is the highest level
  // DOM with an ID that contains the grades table
  var target = document.getElementById('content');

  // create an observer instance
  var observer = new MutationObserver(function(mutations, observer) {
    // For any mutation observed, call bindEventToGradeEntry();
    mutations.forEach(function (mutation) {

      // We only want bindEventToGradeEntry() to be called only when it hasn't been
      // called on a set of grade boxes already. To accomplish this, check if an
      // attribute exists in the table. If it exists, we called bindEventToGradeEntry()
      // already. If not, call bindEventToGradeEntry(), then add the attribute.
      var attr = document.getElementById('grades').attributes['bound'];
      if (attr == undefined) {
        document.getElementById('grades').attributes['bound'] = 'true';
        bindEventToGradeEntry();
      }
    });
});

  // configuration of the observer: we want to detect changes to the subtree (when the
  // grade elements are replaced)
  var config = { childList: true, subtree: true };

  // start observing
  observer.observe(target, config);
});

/** This function will prevent the default HTML5 action of submitting the content form
  *  when the user presses "enter". As an Admin user, this would release the grades.
  */
function preventEnterSubmit() {
  jQuery(document).keypress(function(event) {
    if (event.which == 13) {
      event.preventDefault();
    }
  });
}

/** Updates a cell. Called from Rails controller grade_entry_forms/update_grade to
  * check if a cell exists before updating it, as cell existence can't be efficiently
  * checked from the Ruby controller
  */
function update_cell(cell, value) {
  // If the cell exists, change it's value to the one supplied
  if (document.getElementById(cell)) {
    document.getElementById(cell).value = value;
  }
}

/** Get all of the grade input fields, attach an observer that updates
  * the grade when it is changed
  */
function bindEventToGradeEntry() {
  jQuery('.grade-input').each(function() {
    jQuery(this).change(function() {
      var params = {
        'updated_grade': this.value,
        'student_id': this.dataset.studentid,
        'grade_entry_item_id': this.dataset.gradeentryitemid,
        'authenticity_token': AUTH_TOKEN
      };

      jQuery.ajax({
        url:  this.dataset.action,
        data: params,
        type: 'POST'
      });
    });
  });
}

function toggleTotalColVisibility() {
  var grades_table = document.getElementById('grades_table');

  if (grades_table.hasClass('hideTotal')) {
    grades_table.removeClass('hideTotal');
  } else {
    grades_table.addClass('hideTotal');
  }
}
