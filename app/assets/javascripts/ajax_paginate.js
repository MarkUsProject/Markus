function ap_flip_switches_to(flip_to) {
  $$('input.ap_selectable').each(
    function(node){
      node.setValue(flip_to);
    }
  );
}

function ap_select_all() {
  $('ap_select_full_div').hide();
  $('ap_select_full').setValue('false');
  ap_flip_switches_to(true);
  $('ap_select_all_div').show();
}

function ap_select_full() {
  $('ap_select_all_div').hide();
  $('ap_select_full_div').show();
  $('ap_select_full').setValue('true');
}

function ap_select_none() {
  ap_flip_switches_to(false);
  $('ap_select_all_div').hide();
  $('ap_select_full_div').hide();
  $('ap_select_full').setValue('false');
}

function ap_thinking_start(table_name) { 
  ap_select_none();
  $(table_name).update('');
  $('ap_thinking').show();
}

function ap_thinking_stop() {
  $('ap_thinking').hide();
}
