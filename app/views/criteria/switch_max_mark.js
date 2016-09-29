$('input[type=radio][name=criterion_type]').change(function () {
  console.log($(this).val());

  var value = $(this).val();

  if (value == 'RubricCriterion') {
    document.getElementById('max_mark_prompt').setAttribute('value', '4');
  } else if (value == 'FlexibleCriterion') {
    document.getElementById('max_mark_prompt').setAttribute('value', '1');
  } else if (value == 'CheckboxCriterion') {
    document.getElementById('max_mark_prompt').setAttribute('value', '1');
  }
});