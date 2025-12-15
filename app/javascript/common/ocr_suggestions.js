/**
 * OCR Suggestions Module
 * Handles display and interaction with OCR match data and student suggestions
 * Used in the assign_scans view for exam template processing
 */

export function updateOcrSuggestions(ocrMatch, suggestions = []) {
  const container = $("#ocr_suggestions");
  container.empty();

  if (!ocrMatch) {
    container.hide();
    return;
  }

  container.show();

  // internationalization
  const noId = I18n.t("exam_templates.assign_scans.no_id");
  const idNumber = I18n.t("activerecord.attributes.user.id_number");
  const userName = I18n.t("activerecord.attributes.user.user_name");
  const suggestedStudents = I18n.t("exam_templates.assign_scans.suggested_students");
  const noSimilarStudents = I18n.t("exam_templates.assign_scans.no_similar_students");

  const ocrDisplay = $("<p></p>");
  // Display the parsed OCR value
  const parsedValue = ocrMatch.parsed_value;
  const fieldType = ocrMatch.field_type === "id_number" ? idNumber : userName;
  const ocrDetected = I18n.t("exam_templates.assign_scans.ocr_detected", {field_type: fieldType});

  ocrDisplay.append(`<strong>${ocrDetected}</strong>`);
  const codeElem = $("<code></code>").text(parsedValue);
  ocrDisplay.append(codeElem);
  container.append(ocrDisplay);

  if (suggestions.length == 0) {
    return container.append(`<p class="no-match">${noSimilarStudents}</p>`);
  }

  // Display suggestions if available
  container.append(`<p><strong>${suggestedStudents}</strong></p>`);
  const list = $('<ul class="ui-menu ocr-suggestions-list"></ul>');

  suggestions.forEach(function (suggestion) {
    const similarity = suggestion.similarity;
    const item = $('<li class="ui-menu-item"></li>');
    const content = $("<div></div>");

    // Use .text() to safely insert user-supplied data and prevent XSS
    const nameElem = $("<strong></strong>").text(suggestion.display_name);
    const infoText = `${suggestion.id_number || noId} | ${suggestion.user_name}`;
    const infoElem = $('<span class="student-info"></span>').text(infoText);

    content.append(nameElem);
    content.append(` (${similarity}%)`);
    content.append("<br>");
    content.append(infoElem);

    content.on("click", function () {
      $("#student_id").val(suggestion.id);
      $("#names").val(suggestion.display_name);
      $("#names").focus();
    });

    item.append(content);
    list.append(item);
  });

  container.append(list);
}
