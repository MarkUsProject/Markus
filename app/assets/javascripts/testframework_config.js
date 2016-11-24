/* Removes a newly created test script */
function removeNewTestScript ( remove_check_box ) {
  jQuery(remove_check_box).closest('.test_script').remove();
}

/* Expands/Collapses the settings box for a test script */
function toggleSettings ( collapse_lnk ) {
  collapse_lnk = jQuery(collapse_lnk);

  // find the needed DOM elements
  box = collapse_lnk.closest('.settings_box')

  left_side = box.find('.settings_left_side');
  right_side = box.find('.settings_right_side');

  max_marks = box.find('.maxmarks');
  desc = left_side.find('.desc');
  desc_box = desc.find('textarea');

  if( collapse_lnk.data('collapsed') ) {
    // Was collapsed. Need to expand.
    desc.nextAll('*').show();
    max_marks.nextAll('*').show();

    desc_box.attr('rows', 2);
    max_marks.insertAfter(desc);

    collapse_lnk.text('[-]');
    collapse_lnk.data('collapsed', false);
  } else {
    // Was expanded. Need to collapse.
    right_side.prepend(max_marks);
    desc_box.attr('rows', 1);

    desc.nextAll('*').hide();
    max_marks.nextAll('*').hide();

    collapse_lnk.text('[+]');
    collapse_lnk.data('collapsed', true);
  }
}

/* Expands/Collapses all the settings boxes for the test scripts */
function change_all(which) {
  jQuery('.collapse').each(function (i) {
    if(jQuery(this).data('collapsed')) {
      // This box is collapsed. Can be expanded.
      if(which == 'expand') { toggleSettings(this); }
    } else {
      // This box is expanded. Can be collapsed.
      if(which == 'collapse') { toggleSettings(this); }
    }
  });
}


jQuery(document).ready(function() {
  /* Update the script name in the legend when the admin uploads a file */
  jQuery('.upload_file').change(function () {
    jQuery(this).closest('.settings_box').find('.file_name').text(this.value);
  });

  /* Existing files are collapsed by default */
  jQuery('.collapse').each(function (i) {
    toggleSettings(this);
  });

  /* Make the list of test script files sortable. */
  jQuery( "#test_scripts" ).sortable({
    cancel: ".settings_box",
    stop: function( event, ui) {
      var moved_seqnum_elem = ui.item.find('.seqnum');
      var moved_seqnum = parseFloat(moved_seqnum_elem.val());

      var next_siblings = ui.item.nextAll('div.test_script')
      var prev_siblings = ui.item.prevAll('div.test_script')

      if(prev_siblings.length > 0 && next_siblings.length > 0) {
        // test script file was moved in between two other test scripts
        var next_seqnum = parseFloat( next_siblings.first().find('.seqnum').val() );
        var prev_seqnum = parseFloat( prev_siblings.first().find('.seqnum').val() );
        if(Math.abs(next_seqnum - prev_seqnum) < 1e-6) {
          console.log('difference is too small!')
          next_siblings.find('.seqnum').each(function () {
            this.value = parseFloat(this.value) + 16;
          });
          next_seqnum += 16;
        }
        if( prev_seqnum >= moved_seqnum || moved_seqnum >= next_seqnum ) {
          moved_seqnum_elem.val((prev_seqnum + next_seqnum) / 2);
        }
      } else if(prev_siblings.length > 0) {
        // test script file was moved to the end of the list
        var prev_seqnum = parseFloat( prev_siblings.first().find('.seqnum').val() );
        if( moved_seqnum <= prev_seqnum ) {
          moved_seqnum_elem.val(prev_seqnum + 16);
        }
      } else if(next_siblings.length > 0) {
        // test script file was moved to the front of the list
        var next_seqnum = parseFloat( next_siblings.first().find('.seqnum').val() );
        if( moved_seqnum >= next_seqnum) {
          moved_seqnum_elem.val(next_seqnum - 16);
        }
      } 
    }
  });


  /* Disables form elements when Remove checkbox is checked */
  jQuery( ".remove_test_script_file" ).click(function() {
    if(this.checked) {
      jQuery(this).closest(".settings_box").find(":input").not(this).attr('disabled', true);
    } else {
      jQuery(this).closest(".settings_box").find(":input").attr('disabled', false);
    }
  });
});
