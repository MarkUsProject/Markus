$(document).ready(function() {
  window.modal_create_new   = new ModalMarkus('#create_new_template');
});

function add_template_division(id) {
  var new_id = new Date().getTime();
  var nested_form_path = `exam_template[template_divisions_attributes][${new_id}]`;
  var input_id = 'exam_template_template_divisions_attributes' + new_id;
  var new_division_row = `
    <li id="${input_id}_holder" class="new">
      <span class="label">
        <input type="text" required="required" name="${nested_form_path}[label]">
      </span>
      <span class="start">
        <input type="number" required="required" name="${nested_form_path}[start]">
      </span>
      <span class="end">
        <input type="number" required="required" name="${nested_form_path}[end]">
      </span>
      <span class="delete">
        <a onClick="this.closest('li').remove(); return false;" class="haha">
          ${I18n.t('delete')}
        </a>
      </span>
    </li>
    `;
  $('.template-division-section-' + id + ' .add_template').before(new_division_row);
}

function toggle_cover_page(id, fields) {
  if ($('#exam-cover-checkbox-' + id).is(':checked')) {
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
  $.getScript('https://unpkg.com/jcrop', function()
  {
    var jcp;
    Jcrop.load('crop-target').then(img => {
      jcp = Jcrop.attach(img);
      const rect = Jcrop.Rect.sizeOf(jcp.el);
      const widget = jcp.newWidget(rect.scale(0.9,0.3).center(rect.w,rect.h));
      jcp.focus();
      jcp.listen('crop.change',(widget,_) => {
        const stageHeight = $('#crop-target').height();
        const stageWidth = $('#crop-target').width();
        const { x, y, w, h } = widget.pos;
        // find the input element for width
        // set the width value for that form element
        $('#x').val(x/stageWidth);
        $('#y').val(y/stageHeight);
        $('#width').val(w/stageWidth);
        $('#height').val(h/stageHeight);
      });
      document.getElementsByClassName('jcrop-stage')[0].removeClass('jcrop-image-stage');

      // Initialize form values for initial widget
      const stageHeight = $('#crop-target').height();
      const stageWidth = $('#crop-target').width();
      const { x, y, w, h } = widget.pos;
      // find the input element for width
      // set the width value for that form element
      $('#x').val(x/stageWidth);
      $('#y').val(y/stageHeight);
      $('#width').val(w/stageWidth);
      $('#height').val(h/stageHeight);
    });
  });
}
