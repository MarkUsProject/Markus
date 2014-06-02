function ap_flip_switches_to(flip_to)
  jQuery('input.ap_selectable').each(function(index) {
    $(this).val(flip_to);
  });
}

function ap_select_all() {
  document.getElementById('ap_select_full_div').style.display = 'none';
  document.getElementById('ap_select_full').value = 'false';
  ap_flip_switches_to(true);
  document.getElementById('ap_select_all_div').style.display = '';
}

function ap_select_full() {
  document.getElementById('ap_select_all_div').style.display = 'none';
  document.getElementById('ap_select_full_div').style.display = '';
  document.getElementById('ap_select_full').value = 'true';
}

function ap_select_none() {
  ap_flip_switches_to(false);
  document.getElementById('ap_select_all_div').style.display = 'none';
  document.getElementById('ap_select_full_div').style.display = 'none';
  document.getElementById('ap_select_full').value = 'false';
}

function ap_thinking_start(table_name) {
  ap_select_none();
  document.getElementById(table_name).innerHTML = '';
  document.getElementById('ap_thinking').style.display = '';
}

function ap_thinking_stop() {
  document.getElementById('ap_thinking').style.display = 'none';
}
