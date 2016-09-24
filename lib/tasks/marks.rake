namespace :db do

  desc 'Update fake marks for assignments'
  task :marks => :environment do
    puts 'Assign Marks for Assignments'

    #Right now, only generate marks for two assignments
    Grouping.where(assignment_id: [1, 2]).each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      result = new_submission.results.first
      grouping.is_collected = true
      grouping.save

      #Automate marks for assignment using appropriate criteria
      grouping.assignment.get_criteria(:all, :all, includes: :marks).each do |criterion|
        if criterion.class == RubricCriterion
          random_mark = criterion.max_mark / 4 * rand(0..4)
        elsif criterion.class == FlexibleCriterion
          random_mark = rand(0..criterion.max_mark.to_i)
        else
          random_mark = rand(0..1)
        end
        on_result_creation_mark = Mark.find_by(result_id:     result.id,
                                               markable_id:   criterion.id,
                                               markable_type: criterion.class.to_s)
        on_result_creation_mark.update_attribute(:mark, random_mark)
        result.save
      end
    end

    #Release the marks after they have been inputed into the assignments
    Result.all.each do |result|
      result.marking_state = 'complete'
      result.released_to_students = true
      result.save
    end

    Assignment.where(short_identifier: %w(A1 A2)).each &:update_results_stats

    puts 'Assign Marks for Spreadsheets'
    grade_entry_form = GradeEntryForm.find(1)
    # Add marks to every student
    Student.find_each do |student|
      out_of_total = 0
      grade_entry_form_total = 0
      # For each question, assign a random mark based on its out_of value
      grade_entry_form.grade_entry_items.each do |grade_entry_item|
        random_grade = 1 + rand(0...Integer(grade_entry_item.out_of))
        out_of_total += grade_entry_item.out_of
        Grade.create(grade_entry_student_id: student.id,
                     grade_entry_item_id: grade_entry_item.id,
                     grade: random_grade)
        grade_entry_form_total += random_grade
      end
    end

    # Release spreadsheet grades
    grade_entry_form.grade_entry_students.update_all(released_to_student: true)
  end
end
