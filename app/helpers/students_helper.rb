module StudentsHelper
  def get_students_table_info
    sections = Section.all
    students = Student.includes(:grace_period_deductions, :section)
                      .order('user_name')
    # Gets extra info needed for table, such as grace credits remaining,
    # section name, links to edit, notes, etc.
    students.map do |student|
      s = student.attributes
      s[:edit_link] = url_for(
        controller: 'students',
        action: 'edit',
        id: student.id)
      s[:grace_credits_remaining] = student.remaining_grace_credits
      s[:section_name] = student.has_section? ? student.section.name : nil
      s[:notes_link] = url_for(
        controller: 'notes',
        action: 'notes_dialog',
        id: student.id,
        noteable_id: student.id,
        noteable_type: 'Student',
        action_to: 'note_message',
        controller_to: 'students',
        number_of_notes_field: "num_notes_#{student.id}",
        highlight_field: "notes_highlight_#{student.id}")
      s[:num_notes] = student.notes.size
      s
    end
  end
end
