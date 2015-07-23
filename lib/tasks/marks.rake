namespace :db do

  desc 'Create fake marks for assignments'
  task :marks => :environment do
    puts 'Assign Marks for Assignments'
    markable_rubric = RubricCriterion.first
    Grouping.all.each do |grouping|
      time = grouping.assignment.submission_rule.calculate_collection_time.localtime
      new_submission = Submission.create_by_timestamp(grouping, time)
      result = new_submission.results.first
      grouping.is_collected = true
      grouping.save
      mark = Mark.create(
        result_id: result.id,
        mark: rand(1..5),
        markable_id: rand(1..5),
        markable_type: 'RubricCriterion',
        markable: markable_rubric)
      result.marks.push(mark)
      result.save
      result.marking_state = 'complete'
      result.released_to_students = true
      result.save
    end
  end
end
