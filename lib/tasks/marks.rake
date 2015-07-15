namespace :db do

  desc "Create fake marks for assignments"
  task :marks => :environment do
    puts "Assign Marks for Assignments"
    Grouping.all.each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
        new_submission = Submission.create_by_timestamp(grouping, time)
        result = new_submission.results.first
        mark = Mark.create(result_id: result.id, 
          mark: rand(1..5),
          markable_id: rand(1..5),
          markable_type: "RubricCriterion",
          markable: grouping.assignment.rubric_criteria.first)
        result.marks.push(mark)
        mark.save
        result.save
        new_submission.save
        grouping.save
        result.marking_state = "complete"
        result.released_to_students = true
	result.save
    end
  end
end
