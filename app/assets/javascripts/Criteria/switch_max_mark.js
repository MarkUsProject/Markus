

// var rad = document.myForm.myRadios;
// var prev = null;
// for(var i = 0; i < rad.length; i++) {
//     rad[i].onclick = function() {
//         (prev)? console.log(prev.value):null;
//         if(this !== prev) {
//             prev = this;
//         }
//         console.log(this.value)
//     };
// }
$(document).ready(function() {
    console.log('in script');
    $('input[type=radio][name=criterion_type]').change(function () {
        console.log("changing");
        console.log($(this).val());
        var value = this.value;

        if (value == 'RubricCriterion') {
            document.getElementById('max_mark_prompt').setAttribute('value', '4');
        }
        else if (value == 'FlexibleCriterion') {
            document.getElementById('max_mark_prompt').setAttribute('value', '1');
        }
        else if (value == 'CheckboxCriterion') {
            document.getElementById('max_mark_prompt').setAttribute('value', '1');
        }
    });
});

