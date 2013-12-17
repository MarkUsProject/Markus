jQuery(document).ready(function(){
// document.observe('dom:loaded', function() {

  /**
   * get all of the grade input fields, attach an observer that updates
   * the grade when it is changed
   */
   // $$('.grade-input').each(function(item) {
  jQuery('.grade-input').each(function(item){
	jQuery(item).change(function(element,value){   
		//prototype:  new Form.Element.EventObserver(item, function(element, value) {
		var url = jQuery(this).attr('data-action');
		var params = {
			'updated_grade': value,
			'student_id': jQuery(element).attr('data-student-id'),
			'grade_entry_item_id': jQuery(element).attr('data-grade-entry-item-id'),
			'authenticity_token': AUTH_TOKEN
		}

		// Appel AJAX   
		jQuery.ajax({
		//prototype:      new Ajax.Request(url, {
			type: 'POST',		
			url: url,        
			async: true,
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
