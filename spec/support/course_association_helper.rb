module CourseAssociationHelper
  # Sets the course attribute for +record+ to be +course+. If +record+ does not have a direct
  # association with a course, it finds the correct association by walking through has_one
  # associations until it finds the correct db column value to update.
  #
  # This only sets one column value so this may result in an invalid record if the record in question
  # has multiple belongs_to associations which may now be associated with different courses.
  def set_course!(record, course)
    if record.respond_to?(:course_id)
      record.course = course
      record.save!
    else
      record.class.reflect_on_all_associations(:has_one).each do |ref|
        set_course!(record.public_send(ref.options[:through]), course) if ref.name == :course
      end
    end
  end
end
