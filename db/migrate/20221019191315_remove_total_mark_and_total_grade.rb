class RemoveTotalMarkAndTotalGrade < ActiveRecord::Migration[7.0]
  def up
    remove_column :results, :total_mark
    remove_column :grade_entry_students, :total_grade
  end

  def down
    add_column :grade_entry_students, :total_grade, :float
    add_column :results, :total_mark, :float, default: 0

    puts '-- Recalculating total marks for all Results'
    if Result.respond_to? :update_total_marks
      Result.update_total_marks(Result.ids)
    elsif Result.respond_to? :get_total_marks
      total_marks = Result.get_total_marks(Result.ids)
      view_tokens = Result.where(id: Result.ids).pluck(:id, :view_token).to_h
      unless total_marks.empty?
        Result.upsert_all(
          total_marks.map { |r_id, total_mark| { id: r_id, total_mark: total_mark, view_token: view_tokens[r_id] } }
        )
      end
    end

    puts '-- Recalculating total grades for all GradeEntryStudents'
    if GradeEntryStudent.respond_to? :refresh_total_grades
      GradeEntryStudent.refresh_total_grades(GradeEntryStudent.ids)
    elsif GradeEntryStudent.respond_to? :get_total_grades
      roles = GradeEntryStudent.pluck(:id, :role_id).to_h
      GradeEntryStudent.upsert_all(
        GradeEntryStudent.get_total_grades(GradeEntryStudent.ids)
                         .map { |k, v| {id: k, role_id: roles[k], total_grade: v} }
      )
    end
  end
end
