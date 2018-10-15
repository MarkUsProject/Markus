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
          ${I18n.t('remove')}
        </a>
      </span>
    </li>
    `;
  $('.template-division-section-' + id + ' .add_template').before(new_division_row);
}
