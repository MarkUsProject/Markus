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
    attach_crop_box(id);
  } else {
    $("#exam-cover-display-" + id).css("display", "none");
  }
}

function attach_crop_box(id) {
  var jcrop_api;

  const form = document.getElementById(`add_fields_exam_template_form_${id}`);
  const crop_target = form.getElementsByClassName("crop-target")[0];

  $(crop_target).Jcrop(
    {
      onChange: pos => {
        const stageHeight = parseFloat(
          getComputedStyle(crop_target, null).height.replace("px", "")
        );
        const stageWidth = parseFloat(getComputedStyle(crop_target, null).width.replace("px", ""));
        const {x, y, w, h} = pos;

        form.elements[`${id}_exam_template_crop_x`].value = x / stageWidth;
        form.elements[`${id}_exam_template_crop_y`].value = y / stageHeight;
        form.elements[`${id}_exam_template_crop_width`].value = w / stageWidth;
        form.elements[`${id}_exam_template_crop_height`].value = h / stageHeight;
      },
      keySupport: false,
      boxWidth: $("#scalex").val(),
      boxHeight: $("#scaley").val(),
    },
    function () {
      jcrop_api = this;
    }
  );

  // Set crop selection if values exist.
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

  $("#target").on("click", function () {
    jcrop_api.destroy();
    scalex = $("#scalex").val();
    scaley = $("#scaley").val();
    $(crop_target).Jcrop(
      {
        onChange: pos => {
          const stageHeight = parseFloat(
            getComputedStyle(crop_target, null).height.replace("px", "")
          );
          const stageWidth = parseFloat(
            getComputedStyle(crop_target, null).width.replace("px", "")
          );
          const {x, y, w, h} = pos;

          form.elements[`${id}_exam_template_crop_x`].value = x / stageWidth;
          form.elements[`${id}_exam_template_crop_y`].value = y / stageHeight;
          form.elements[`${id}_exam_template_crop_width`].value = w / stageWidth;
          form.elements[`${id}_exam_template_crop_height`].value = h / stageHeight;
        },
        keySupport: false,
        boxWidth: $("#scalex").val(),
        boxHeight: $("#scaley").val(),
      },
      function () {
        jcrop_api = this;
      }
    );
  });
}
