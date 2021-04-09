$(document).ready(function() {
  window.modal_create_new   = new ModalMarkus('#create_new_template');
});

function add_template_division() {
  var new_id = new Date().getTime();
  var nested_form_path = `exam_template[template_divisions_attributes][${new_id}]`;
  var input_id = 'exam_template_template_divisions_attributes' + new_id;
  var new_division_row = `
    <tr id="${input_id}_holder" class="new">
      <td>
        <input type="text" required="required" name="${nested_form_path}[label]">
      </td>
      <td>
        <input type="number" required="required" name="${nested_form_path}[start]">
      </td>
      <td>
        <input type="number" required="required" name="${nested_form_path}[end]">
      </td>
      <td>
        <a onClick="this.closest('li').remove(); return false;" class="haha">
          ${I18n.t('delete')}
        </a>
      </td>
    </tr>
    `;
  $('.table-with-add tbody').append(new_division_row);
}

function toggle_cover_page(id, fields) {
  if ($('#automatic_parsing').is(':checked')) {
    $('#exam-cover-display-' + id).css('display', 'flex');
    var i;
    for (i=0; i<fields.length; i++) {
      $('.field' + (i+1)).val(fields[i]);
    }
    attach_crop_box();
  } else {
    $('#exam-cover-display-' + id).css('display', 'none');
  }
}

function attach_crop_box() {
  var jcrop_api;

  $('#crop-target').Jcrop({
    onChange: pos => {
      const stageHeight = $('#crop-target').height();
      const stageWidth = $('#crop-target').width();
      const { x, y, w, h } = pos;
      // find the input element for width
      // set the width value for that form element
      $('#x').val(x/stageWidth);
      $('#y').val(y/stageHeight);
      $('#width').val(w/stageWidth);
      $('#height').val(h/stageHeight);
    }
  }, function () {
    jcrop_api = this;
  });

  // Set crop selection if values exist.
  if ($('#x').val() && $('#y').val() && $('#width').val() && $('#height').val()) {
    const stageHeight = $('#crop-target').height();
    const stageWidth = $('#crop-target').width();
    const x = parseFloat($('#x').val()) * stageWidth;
    const y = parseFloat($('#y').val()) * stageHeight;
    const width = parseFloat($('#width').val()) * stageWidth;
    const height = parseFloat($('#height').val()) * stageHeight;
    jcrop_api.setSelect([x, y, x + width, y + height]);
  }
}
