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
      $('grade_entry_form_grade_entry_items_' + new_grade_entry_item_id + '_name').focus();
      }
    end
  end

  # Release/unrelease the marks for a grade entry form for the given
  # grade_entry_students
  # Return the number of GradeEntryStudents that have been updated successfully
  def set_release_on_grade_entry_students(grade_entry_students, release, errors)
    numGradeEntryStudentsChanged = 0
    grade_entry_students.each do |grade_entry_student|
      begin
        grade_entry_student.released_to_student = release
        unless grade_entry_student.save
          raise I18n.t('grade_entry_forms.grades.update_error',
                       :user_name => grade_entry_student.user.user_name)
        end
        numGradeEntryStudentsChanged += 1
      rescue Exception => e
        errors.push(e.message)
      end
    end
    numGradeEntryStudentsChanged
  end

end
