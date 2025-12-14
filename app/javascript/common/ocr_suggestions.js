/**
 * OCR Suggestions Module
 * Handles display and interaction with OCR match data and student suggestions
 * Used in the assign_scans view for exam template processing
 */

export function updateOcrSuggestions(ocrMatch, suggestions) {
  const container = $("#ocr_suggestions");
  container.empty();

  if (!ocrMatch) {
    container.hide();
    return;
  }

  container.show();

  // Display the parsed OCR value
  const parsedValue = ocrMatch.parsed_value;
  const fieldType = ocrMatch.field_type === "id_number" ? "ID Number" : "Username";
  const ocrDisplay = $("<p></p>");
  ocrDisplay.append(`<strong>OCR Detected ${fieldType}:</strong> `);
  const codeElem = $("<code></code>").text(parsedValue);
  ocrDisplay.append(codeElem);
  container.append(ocrDisplay);

  // Display suggestions if available
  if (suggestions && suggestions.length > 0) {
    container.append("<p><strong>Suggested Students:</strong></p>");
    const list = $('<ul class="ui-menu ocr-suggestions-list"></ul>');

    suggestions.forEach(function (suggestion) {
      const similarity = suggestion.similarity;
      const item = $('<li class="ui-menu-item"></li>');
      const content = $("<div></div>");

      // Use .text() to safely insert user-supplied data and prevent XSS
      const nameElem = $("<strong></strong>").text(suggestion.display_name);
      const infoText = `${suggestion.id_number || "No ID"} | ${suggestion.user_name}`;
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
  } else if (!ocrMatch.matched) {
    container.append('<p class="no-match">No similar students found. Please assign manually.</p>');
  }
}
