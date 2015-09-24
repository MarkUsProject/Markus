# Helper methods for grade entry forms

module GradeEntryFormsHelper

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
                       user_name: grade_entry_student.user.user_name)
        end
        numGradeEntryStudentsChanged += 1
      rescue Exception => e
        errors.push(e.message)
      end
    end
    numGradeEntryStudentsChanged
  end

  # Removes items that have empty names (so they don't get updated)
  def update_grade_entry_form_params(attributes)
    grade_entry_items =
      params[:grade_entry_form][:grade_entry_items_attributes]

    unless grade_entry_items.nil?
      # Update the attributes hash
      max_position = 1
      grade_entry_items.each do |_, item|
        # Some items are being deleted so don't update those
        unless item[:_destroy]
          item[:position] = max_position
          max_position += 1
        end
      end
    end
    attributes[:grade_entry_items_attributes] = grade_entry_items
    grade_entry_form_params(attributes)
  end

  def sort_items_by_position(items)
    sorted = items.sort_by { |hsh| hsh[:position] }
  end

  private

  def grade_entry_form_params(attributes)
    attributes.require(:grade_entry_form)
              .permit(:description,
                      :message,
                      :date,
                      :show_total,
                      :short_identifier,
                      :is_hidden,
                      grade_entry_items_attributes: [:name,
                                                     :out_of,
                                                     :position,
                                                     :bonus,
                                                     :_destroy,
                                                     :id])
  end
end
