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
  container.append(
    `<p><strong>OCR Detected ${fieldType}:</strong> <code>${parsedValue}</code></p>`
  );

  // Display suggestions if available
  if (suggestions && suggestions.length > 0) {
    container.append("<p><strong>Suggested Students:</strong></p>");
    const list = $('<ul class="ui-menu ocr-suggestions-list"></ul>');

    suggestions.forEach(function (suggestion) {
      const similarity = suggestion.similarity;
      const item = $('<li class="ui-menu-item"></li>');
      const content = $("<div></div>");

      content.html(`
        <strong>${suggestion.display_name}</strong> (${similarity}%)<br>
        <span class="student-info">${suggestion.id_number || "No ID"} | ${suggestion.user_name}</span>
      `);

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
