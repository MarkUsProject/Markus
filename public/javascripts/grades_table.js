document.observe('dom:loaded', function() {

  /**
   * get all of the grade input fields, attach an observer that updates
   * the grade when it is changed
   */
  $$('.grade-input').each(function(item) {
    new Form.Element.EventObserver(item, function(element, value) {

      var url = element.readAttribute('data-action');
      var params = {
        'updated_grade': value,
        'student_id': element.readAttribute('data-student-id'),
        'grade_entry_item_id': element.readAttribute('data-grade-entry-item-id'),
        'authenticity_token': AUTH_TOKEN
      }

      new Ajax.Request(url, {
        asynchronous: true,
        evalScripts: true,
        parameters: params
      });
    });
  });
});