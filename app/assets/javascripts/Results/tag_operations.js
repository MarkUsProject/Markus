function formatTag(type, tag_id, grouping_id) {
    //Notifies that the system is working.
    document.getElementById('working').style.display = '';

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

  // Replace 'add' with 'remove'
  spanElement.replace('add', 'remove');
  alert('<span id="' + tag_id + '" class="tag_element">' + spanElement + '</span>');
  // Now goes to insert it.
  jQuery("#active_tags").append(
      '<span id="' + tag_id + '" class="tag_element">' + spanElement + '</span>');

  // Finally, deletes the current element.
  jQuery('span#' + tag_id).remove();

  // Checks and sees if there are no tags in the available tags.
  if (jQuery('div#available_tags').length == 1) {
    jQuery('span#available-none').removeClass('no_tags_hidden');
    jQuery('span#available-none').addClass('no_tags');
  }

  // Checks and sees if there are no tags in the active tags.
  if (jQuery('div#active_tags').length == 1) {
      jQuery('span#active-none').removeClass('no_tags');
      jQuery('span#active-none').addClass('no_tags_hidden');
  }
}

function addTagToAvailable(tag_id) {
  // We get the old tag text.
  var spanElement = jQuery('span#' + tag_id).html();

  // Replace 'add' with 'remove'
  spanElement.replace('remove', 'add');

  // Now goes to insert it.
  jQuery("#available_tags").append(
          '<span id="' + tag_id + '" class="tag_element">' + spanElement + '</span>');

  // Finally, deletes the current element.
  jQuery('span#' + tag_id).remove();

  // Checks and sees if there are no tags in the active tags.
  if (jQuery('div#active_tags').length == 1) {
      jQuery('span#active-none').removeClass('no_tags_hidden');
      jQuery('span#active-none').addClass('no_tags');
  }

  // Checks and sees if there are no tags in the available tags.
  if (jQuery('div#available_tags').length == 1) {
      jQuery('span#available-none').removeClass('no_tags');
      jQuery('span#available-none').addClass('no_tags_hidden');
  }
}