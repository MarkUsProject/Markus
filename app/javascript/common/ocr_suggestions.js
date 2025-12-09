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
    const list = $('<ul class="ocr-suggestions-list"></ul>');

    suggestions.forEach(function (suggestion) {
      const similarity = suggestion.similarity;
      const colorClass =
        similarity >= 90 ? "high-match" : similarity >= 70 ? "medium-match" : "low-match";
      const item = $('<li class="ocr-suggestion-item"></li>');
      const link = $(`<a href="#" class="ocr-suggestion-link ${colorClass}"></a>`);

      link.html(`
        <span class="student-name">${suggestion.display_name}</span>
        <span class="student-details">${suggestion.user_name} | ${suggestion.id_number || "No ID"}</span>
        <span class="similarity-badge">${similarity}% match</span>
      `);

      link.on("click", function (e) {
        e.preventDefault();
        $("#student_id").val(suggestion.id);
        $("#names").val(suggestion.display_name);
        $("#names").focus();
      });

      item.append(link);
      list.append(item);
    });

    container.append(list);
  } else if (!ocrMatch.matched) {
    container.append(
      '<p class="no-suggestions">No similar students found. Please assign manually.</p>'
    );
  }
}
