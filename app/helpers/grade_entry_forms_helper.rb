# Helper methods for grade entry forms

module GradeEntryFormsHelper

  # Allow the user to create a new column for the grade entry form.  
  # This JavaScript below is necessary because it is possible for the GradeEntryForm
  # to not exist yet when the form fields come up (i.e. when an instructor
  # is creating a new grade entry form).
  def add_grade_entry_item_link(name, form)
    link_to_function name do |page|
      grade_entry_item = render(:partial => 'grade_entry_item', 
                                :locals => {:form => form, :grade_entry_item => GradeEntryItem.new})
      page << %{
      var new_grade_entry_item_id = "new_" + new Date().getTime();
      $('grade_entry_items').insert({bottom: "#{ escape_javascript grade_entry_item }".replace(/attributes_\\d+|\\d+\(?=\\]\)/g, new_grade_entry_item_id) });
      }
    end
  end
   
end
