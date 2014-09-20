function ap_flip_switches_to(flip_to) {
  var inputs = document.getElementsByClassName('ap_selectable');

  for (var i = 0; i < inputs.length; i++) {
    if (flip_to) {
      inputs[i].setAttribute('checked', 'true');
    } else {
      inputs[i].removeAttribute('checked');
    }
  }
}

function ap_select_all() {
  document.getElementById('ap_select_full_div').style.display = 'none';
  document.getElementById('ap_select_all_div').style.display = '';
  document.getElementById('ap_select_full').value = 'false';
  ap_flip_switches_to(true);
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
  document.getElementById('working').style.display = '';
}

function ap_thinking_stop() {
  document.getElementById('working').style.display = 'none';
}
