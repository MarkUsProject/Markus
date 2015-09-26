namespace :db do
  
  desc 'Create remark requests for assignments'
  task :remarks => :environment do
    puts 'Create remark requests'

    # Only submit remark request for assignments that allow them
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
            submission_id: submission.id)
          remark.save

          # Update subission
          submission.update(
            remark_result_id: remark.id,
            remark_request: 'Please remark my assignment.',
            remark_request_timestamp: Time.zone.now)

          submission.remark_result.update_attributes(
            marking_state: Result::MARKING_STATES[:partial])
        end
      end
  end 
end