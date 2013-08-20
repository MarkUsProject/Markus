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

function toggleTotalColVisibility() {
    var allElements = document.getElementsByClassName("total_value");

    for(var i=0; i < allElements.length; i++)
    {
	if(allElements [i].style.display == 'inline-block')
	  allElements [i].style.display = 'none';
	else
	  allElements [i].style.display = 'inline-block';
    }
	
}
