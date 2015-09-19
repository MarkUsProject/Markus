namespace :db do

  desc 'Create fake marks for assignments'
  task :marks => :environment do
    puts 'Assign Marks for Assignments'

    #Function used to create marks for both criterias
    def create_mark(result_id, markable_type, markable)
      Mark.create(
        result_id: result_id,
        mark: rand(0..4),
        markable_type: markable_type,
        markable: markable)
    end

    #Right now, only generate marks for two assignments
    Grouping.where(assignment_id: [1, 2]).each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      result = new_submission.results.first
      grouping.is_collected = true
      grouping.save

      #Automate marks for assignment using flexible criteria
      if grouping.assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:flexible]
       grouping.assignment.flexible_criteria.each do |flexible|
        mark = create_mark(result.id, grouping.assignment.marking_scheme_type, flexible)
        result.marks.push(mark)
        result.save
       end
      end

      #Automate marks for assignment using rubric criteria
      if grouping.assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:rubric]
        grouping.assignment.rubric_criteria.each do |rubric|
          mark = create_mark(result.id, grouping.assignment.marking_scheme_type, rubric)
          result.marks.push(mark)
          result.save
        end
      end
    end

    #Release the marks after they have been inputed into the assignments
    Result.all.each do |result|
      result.marking_state = 'complete'
      result.released_to_students = true
      result.save
    end

    Assignment.find([1, 2]).each { |a| a.update_results_stats }
  end
end
