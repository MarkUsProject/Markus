document.observe('dom:loaded', function () {

    // Bind the 'send data to db' event to all grade id boxes
    bindEventToGradeEntry();

    /**
     Because the page has loaded and 'dom:loaded' has fired, we can't
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
    var target = document.querySelector('#content');

    // create an observer instance
    var observer = new MutationObserver(function(mutations) {
        // For any mutation observed, call bindEventToGradeEntry();
        mutations.forEach(function(mutation) {
            bindEventToGradeEntry();
        });
    });

    // configuration of the observer: we want to detect changes to the subtree (when the
    // grade elements are replaced)
    var config = { childList: true, subtree: true };

    // start observing
    observer.observe(target, config);

});

/**
 * get all of the grade input fields, attach an observer that updates
 * the grade when it is changed
 */
function bindEventToGradeEntry() {
    $$('.grade-input').each(function (item) {
        new Form.Element.EventObserver(item, function (element, value) {

            var url = element.readAttribute('data-action');
            var params = {
                'updated_grade': value,
                'student_id': element.readAttribute('data-student-id'),
                'grade_entry_item_id': element.readAttribute('data-grade-entry-item-id'),
                'authenticity_token': AUTH_TOKEN
            }

            new Ajax.Request(url, {
                asynchronous: true,
                evalScripts: true,
                parameters: params
            });
        });
    });
}

function toggleTotalColVisibility() {
    var allElements = document.getElementsByClassName("total_value");

    for (var i = 0; i < allElements.length; i++) {
        if (allElements [i].style.display == 'inline-block')
            allElements [i].style.display = 'none';
        else
            allElements [i].style.display = 'inline-block';
    }

}
