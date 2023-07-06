let crop_scale = 600;
const SCALE_CHANGE = 100;
let MIN_SIZE = 600;
let jcrop_api;

$(document).ready(function () {
  window.modal_create_new = new ModalMarkus("#create_new_template");
  $("#generate_exam_modal_submit").click(() => {
    $("#generate_exam_dialog").trigger("closeModal");
  });
  $(".add-template-division").click(e => {
    add_template_division(e.target);
    e.preventDefault();
  });
});

/**
 * Initialize an exam template form.
 * @param id Exam template id
 */
const init_exam_template_form = id => {
  const form = document.getElementById(`add_fields_exam_template_form_${id}`);
  const parsing_input = form && form.elements[`${id}_exam_template_automatic_parsing`];

  parsing_input.addEventListener("change", () => toggle_cover_page(id));

  const crop_target = form.getElementsByClassName("crop-target")[0];
  crop_target.onload = () => toggle_cover_page(id);
};

function add_template_division(target) {
  var new_id = new Date().getTime();
  var nested_form_path = `exam_template[template_divisions_attributes][${new_id}]`;
  var input_id = "exam_template_template_divisions_attributes" + new_id;
  var new_division_row = `
    <tr id="${input_id}_holder" class="new">
      <td>
        <input type="text" required="required" name="${nested_form_path}[label]">
      </td>
      <td>
        <input type="number" min="2" required="required" name="${nested_form_path}[start]">
      </td>
      <td>
        <input type="number" min="2" required="required" name="${nested_form_path}[end]">
      </td>
      <td>
        <a href="#" class="delete-exam-template-row">
          ${I18n.t("delete")}
        </a>
      </td>
    </tr>
    `;
  $(target).parent(".table-with-add").find("tbody").append(new_division_row);
  $(".delete-exam-template-row").click(e => {
    $(e.target).parents("tr").remove();
    e.preventDefault();
  });
}

function toggle_cover_page(id) {
  const form = document.getElementById(`add_fields_exam_template_form_${id}`);
  const parsing_input = form && form.elements[`${id}_exam_template_automatic_parsing`];
  if (parsing_input === null || parsing_input === undefined) {
    return;
  }

  if (parsing_input.checked) {
    $("#exam-cover-display-" + id).css("display", "flex");

    const image_container_width = $("#exam-crop-img-container").width();
    const image_container_width_rounded_down =
      _round_down_to_nearest_hundred(image_container_width);
    crop_scale = image_container_width_rounded_down;
    MIN_SIZE = image_container_width_rounded_down;

    attach_crop_box(id);
    toggle_crop_scale_buttons(id);
  } else {
    $("#exam-cover-display-" + id).css("display", "none");
  }
}

/**
 * TODO: Refactor below functions so there are no hard dependencies on the crop_target having
 *  a certain class name, and relying on a form to grab widths and heights.
 */

/**
 * Initialize a crop object and attach a crop box to an exam template with class crop-target, using
 * form data to specify the dimensions of the crop box. If the form data does not exist, no crop
 * selection is displayed.
 * @param id Exam template identifier.
 */
function attach_crop_box(id) {
  const form = document.getElementById(`add_fields_exam_template_form_${id}`);
  const crop_target = form.getElementsByClassName("crop-target")[0];

  if (jcrop_api !== undefined) {
    jcrop_api.destroy();
  }

  jcrop_api = config_jcrop_api(crop_target, form, id);

  // Set crop selection if values exist.
  set_crop_selection(crop_target, form, id, jcrop_api);
}

/**
 * Initialize event listeners for the crop zoom buttons on the exam template.
 * @param id Exam template identifier.
 */
function toggle_crop_scale_buttons(id) {
  $("#decrease-crop-scale").on("click", function () {
    if (crop_scale - SCALE_CHANGE < MIN_SIZE) {
      crop_scale = MIN_SIZE;
    } else {
      crop_scale -= SCALE_CHANGE;
    }

    attach_crop_box(id);
  });

  $("#increase-crop-scale").on("click", function () {
    crop_scale += SCALE_CHANGE;
    attach_crop_box(id);
  });
}

/**
 * Configure a Jcrop object and attach it to a target.
 * @param crop_target Target to attach crop box to. Must be an exam template.
 * @param form Form containing information of the crop selection for the target (exam template).
 * @param id Exam template identifier.
 * @returns Configured Jcrop object.
 */
function config_jcrop_api(crop_target, form, id) {
  return $.Jcrop(crop_target, {
    onChange: pos => {
      const stageHeight = parseFloat(getComputedStyle(crop_target, null).height.replace("px", ""));
      const stageWidth = parseFloat(getComputedStyle(crop_target, null).width.replace("px", ""));
      const {x, y, w, h} = pos;

      form.elements[`${id}_exam_template_crop_x`].value = x / stageWidth;
      form.elements[`${id}_exam_template_crop_y`].value = y / stageHeight;
      form.elements[`${id}_exam_template_crop_width`].value = w / stageWidth;
      form.elements[`${id}_exam_template_crop_height`].value = h / stageHeight;
    },
    keySupport: false,
    boxWidth: crop_scale,
    boxHeight: crop_scale,
    addClass: "jcrop-centered",
  });
}

/**
 * Display a crop selection onto a target image, given a selection has been saved.
 * @param crop_target Target to display crop selection onto. Must be an exam template.
 * @param form Form containing information of the crop selection for the target (exam template).
 * @param id Exam template identifier.
 * @param jcrop_api Configured Jcrop object that has been attached to crop_target already.
 */
function set_crop_selection(crop_target, form, id, jcrop_api) {
  if (
    form.elements[`${id}_exam_template_crop_x`].value &&
    form.elements[`${id}_exam_template_crop_y`].value &&
    form.elements[`${id}_exam_template_crop_width`].value &&
    form.elements[`${id}_exam_template_crop_height`].value
  ) {
    const stageHeight = parseFloat(getComputedStyle(crop_target, null).height.replace("px", ""));
    const stageWidth = parseFloat(getComputedStyle(crop_target, null).width.replace("px", ""));
    const x = parseFloat(form.elements[`${id}_exam_template_crop_x`].value) * stageWidth;
    const y = parseFloat(form.elements[`${id}_exam_template_crop_y`].value) * stageHeight;
    const width = parseFloat(form.elements[`${id}_exam_template_crop_width`].value) * stageWidth;
    const height = parseFloat(form.elements[`${id}_exam_template_crop_height`].value) * stageHeight;

    jcrop_api.setSelect([x, y, x + width, y + height]);
  }
}

/**
 * Round a number down to the nearest hundred.
 * @param num Number to round down.
 * @returns {number} Number rounded down to the nearest hundred.
 * @private
 */
function _round_down_to_nearest_hundred(num) {
  return Math.floor(num / 100) * 100;
}
