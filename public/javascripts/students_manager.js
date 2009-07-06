document.observe('dom:loaded', function() {
  $$('.hidden_student').each(function(node) {
    $(node).hide();
  });
});
