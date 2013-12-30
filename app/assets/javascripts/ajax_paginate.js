function ap_flip_switches_to(flip_to) {
jQuery.each(('input.ap_selectable'),function() {node.val(flip_to);
    }
  );
}

function ap_select_all() {
  jQuery('#ap_select_full_div').hide();
  jQuery('#ap_select_full').val('false');
  ap_flip_switches_to(true);
  jQuery('#ap_select_all_div').show();
}

function ap_select_full() {
  jQuery('#ap_select_all_div').hide();
  jQuery('#ap_select_full_div').show();
  jQuery('#ap_select_full').val('true');
}

function ap_select_none() {
  ap_flip_switches_to(false);
  jQuery('#ap_select_all_div').hide();
  jQuery('#ap_select_full_div').hide();
  jQuery('#ap_select_full').val('false');
}

function ap_thinking_start(table_name) { 
  ap_select_none();
  jQuery('#table_name').html('');
  jQuery('#ap_thinking').show();
}

function ap_thinking_stop() {
  jQuery('#ap_thinking').hide();
}
