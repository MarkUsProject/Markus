namespace :db do
  desc 'Create remark requests for assignments'
  task :remarks => :environment do
    puts 'Create remark requests'

    #Function used to create marks for both criterias
    def create_mark(result_id, markable_type, markable)
      Mark.create(
        result_id: result_id,
        mark: rand(0..4),
        markable_type: markable_type,
        markable: markable)
    end

    # Create remark requests for assignments that allow them
    Assignment.where("allow_remarks").each do |assignment|

      # Create remark request for first two groups in each assignment
      Grouping.where(assignment_id: assignment.id).first(2).each do |grouping|
        submission = Submission.find_by_grouping_id(grouping.id)

        original_result = Result.find_by_submission_id(submission.id)
        original_result.released_to_students = false
        original_result.save

        # Create new entry in results table for the remark
        remark = Result.new(
          marking_state: Result::MARKING_STATES[:unmarked],
          submission_id: submission.id,
          remark_request_submitted_at: Time.zone.now)
        remark.save

        # Update subission
        submission.update(
          remark_request: 'Please remark my assignment.',
          remark_request_timestamp: Time.zone.now)

        submission.remark_result.update_attributes(
          marking_state: Result::MARKING_STATES[:partial])
      end
    end

    # Remark one of the remark requests and release it to students

    remark_submission = Result.where.not(remark_request_submitted_at: nil).first.submission
    remark_group = Grouping.find_by_group_id(remark_submission.grouping_id)
    result = remark_submission.results.first

    #Automate remarks for assignment using flexible criteria
    if remark_group.assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:flexible]
      remark_group.assignment.flexible_criteria.each do |flexible|
        mark = create_mark(remark_submission.remark_result.id,
                            remark_group.assignment.marking_scheme_type,
                            flexible)
        result.marks.push(mark)
        result.save
      end
    end

    #Automate remarks for assignment using rubric criteria
    if remark_group.assignment.marking_scheme_type == Assignment::MARKING_SCHEME_TYPE[:rubric]
      remark_group.assignment.rubric_criteria.each do |rubric|
        mark = create_mark(remark_submission.remark_result.id,
                            remark_group.assignment.marking_scheme_type,
                            rubric)
        result.marks.push(mark)
        result.save
      end
    end

    remark_submission.remark_result.update_attributes(
      marking_state: Result::MARKING_STATES[:complete],
      released_to_students: true)
  end 
end