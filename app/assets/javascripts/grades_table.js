jQuery(document).ready(function(){
// document.observe('dom:loaded', function() {

  /**
   * get all of the grade input fields, attach an observer that updates
   * the grade when it is changed
   */
  jQuery('.grade-input').change(function(element,value) {
	//prototype: new Form.Element.EventObserver(jQuery(this), function(element, value) {     
	alert("Hey !");	
	var url = jQuery(this).attr('data-action');
	var params = {
		'updated_grade': value,
		'student_id': jQuery(this).attr('data-student-id'),
		'grade_entry_item_id': jQuery(this).attr('data-grade-entry-item-id'),
		'authenticity_token': AUTH_TOKEN
	}
	// Appel AJAX
	      }).trigger('change');
	});
   
	jQuery.ajax({
	//prototype:      new Ajax.Request(url, {
		url: url,        
		async: true,
		parameters: params
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
