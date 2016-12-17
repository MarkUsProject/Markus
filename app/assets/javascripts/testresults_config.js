/* Expands/Collapses the box for an automated test result */
function toggleResult(collapse_lnk) {
    collapse_lnk = jQuery(collapse_lnk);
    // find the needed DOM elements
    test_result = collapse_lnk.closest('.test-result');
    box = test_result.find('.results_table');
    
    if (collapse_lnk.text() === 'Show Results') {
        box.show();
        collapse_lnk.text('Hide Results');
        collapse_lnk.data('collapsed', false);
    } else {
        box.hide();
        collapse_lnk.text('Show Results');
        collapse_lnk.data('collapsed', true);
    }
}

function hideIfNotLatest(latest_date, element_id) {
    result = document.getElementById(element_id);
    if (element_id !== latest_date) {
        result.style.display = 'none';
    }
}
