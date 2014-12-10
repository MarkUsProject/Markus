function formatTag(type, tag_id, grouping_id) {
    //Gets the tag element
    var tag = jQuery('span#' + tag_id);
    // Notifies that the system is working.
    document.getElementById('working').style.display = '';

    // Disables hyperlink.
    tag.removeClass('tag_element');
    tag.addClass('tag_element_disabled');

    // Performs an AJAX call to add the tag.
    jQuery.ajax({
      method: 'GET',
      data: {
              type: type,
              tag_id: tag_id,
              grouping_id: grouping_id
            },
      dataType: 'json',
      error: function(xhr, status, text) {
        //TODO: Add error message.
      },
      complete: function() {
        // Remove working notice.
        document.getElementById('working').style.display = 'none';

        // Re-enable the tag.
        tag.removeClass('tag_element_disabled');
        tag.addClass('tag_element');

        // Handle tag movement.
        if (type === "add")
          addTagToCurrent(tag_id);
        else
          addTagToAvailable(tag_id);
      }
    });
}

function addTagToCurrent(tag_id) {
  // We get the old tag text.
  var spanElement = jQuery('span#' + tag_id).html();

  // Finally, deletes the current element.
  jQuery('span#' + tag_id).remove();

  // Replace 'add' with 'remove'
  spanElement = spanElement.replace(/add/g, 'remove');

  // Now goes to insert it.
  jQuery("#active_tags").append(
      '<span id="' + tag_id + '" class="tag_element">' + spanElement + '</span>');

  // Checks and sees if there are no tags in the available tags.
  if (jQuery('#available_tags span').length == 1) {
    jQuery('span#available-none').removeClass('no_tags_hidden');
    jQuery('span#available-none').addClass('no_tags');
  }

  // Checks and sees if there are no tags in the active tags.
  if (jQuery('#active_tags span').length == 1) {
      jQuery('span#active-none').removeClass('no_tags');
      jQuery('span#active-none').addClass('no_tags_hidden');
  }
}

function addTagToAvailable(tag_id) {
  // We get the old tag text.
  var spanElement = jQuery('span#' + tag_id).html();

  // Finally, deletes the current element.
  jQuery('span#' + tag_id).remove();

   // Replace 'add' with 'remove'
  spanElement = spanElement.replace(/remove/g, 'add');

  // Now goes to insert it.
  jQuery("#available_tags").append(
          '<span id="' + tag_id + '" class="tag_element">' + spanElement + '</span>');

  // Checks and sees if there are no tags in the active tags.
  if (jQuery('#active_tags span').length == 1) {
      jQuery('span#active-none').removeClass('no_tags_hidden');
      jQuery('span#active-none').addClass('no_tags');
  }

  // Checks and sees if there are no tags in the available tags.
  if (jQuery('#available_tags span').length == 1) {
      jQuery('span#available-none').removeClass('no_tags');
      jQuery('span#available-none').addClass('no_tags_hidden');
  }
}