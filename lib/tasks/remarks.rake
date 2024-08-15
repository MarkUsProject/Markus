namespace :db do
  desc 'Create remark requests for assignments'
  task remarks: :environment do
    puts 'Create remark requests'

    # Create remark requests for assignments that allow them
    Assignment.joins(:assignment_properties)
              .where(assignment_properties: { allow_remarks: true })
              .find_each do |assignment|
      # Create remark request for first two groups in each assignment
      Grouping.where(assessment_id: assignment.id).first(2).each do |grouping|
        submission = Submission.find_by(grouping_id: grouping.id)

        original_result = Result.find_by(submission_id: submission.id)
        original_result.released_to_students = false
        original_result.save

        # Create new entry in results table for the remark
        remark = Result.new(
          marking_state: Result::MARKING_STATES[:incomplete],
          submission_id: submission.id,
          remark_request_submitted_at: Time.current
        )
        remark.save

        # Update subission
        submission.update(
          remark_request: 'Please remark my assignment.',
          remark_request_timestamp: Time.current
        )

        submission.remark_result.update(marking_state: Result::MARKING_STATES[:incomplete])
      end
    end

    # Remark one of the remark requests and release it to students
    remark_submission = Result.where.not(remark_request_submitted_at: nil).first.submission
    result = remark_submission.results.first

    # Automate remarks for assignment using appropriate criteria
    remark_submission.assignment.criteria.includes(:marks).find_each do |criterion|
      if criterion.instance_of?(RubricCriterion)
        random_mark = criterion.max_mark / 4 * rand(0..4)
      elsif criterion.instance_of?(FlexibleCriterion)
        random_mark = rand(0..criterion.max_mark.to_i)
      else
        random_mark = rand(0..1)
      end
      mark = Mark.find_by(result_id: remark_submission.remark_result.id,
                          criterion_id: criterion.id)
      mark.update_attribute(:mark, random_mark)
      result.save
    end

    remark_submission.remark_result.update(
      marking_state: Result::MARKING_STATES[:complete],
      released_to_students: true
    )
  end
end
