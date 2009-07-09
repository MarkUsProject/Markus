document.observe('dom:loaded', function() {
  $$('.hidden_student').each(function(node) {
    $(node).hide();
  });
});

function toggle_students_selection(students_all) {
  if(students_all){
    $$('#students tbody input').each(function(e){
      e.setValue(true);
      }
    );
    }else{
      $$('#students tbody input').each(function(e){
        e.setValue(false);
      }
    );
    }
}
