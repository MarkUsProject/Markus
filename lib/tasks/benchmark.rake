# Benchmark test data for performance testing.
#
# Usage:
#   rake markus:benchmark:create
#   NUM_ASSIGNMENTS=10 GROUPINGS=100 rake markus:benchmark:create
#   rake markus:benchmark:cleanup
#
# Tests repository permissions (get_student_permissions_bulk) and
# TA statistics (cache_ta_results).

require 'factory_bot_rails'

namespace :markus do
  namespace :benchmark do
    DATA_FILE = Rails.root.join('tmp/benchmark_data.json')

    desc 'Create benchmark test data'
    task create: :environment do
      num_assignments = ENV.fetch('NUM_ASSIGNMENTS', '5').to_i
      num_groupings = ENV.fetch('GROUPINGS', '50').to_i
      complete_ratio = ENV.fetch('COMPLETE_RATIO', '0.5').to_f
      timestamp = Time.now.to_i

      course = Course.first
      abort 'No course found. Run db:seed first.' unless course

      puts "Creating #{num_assignments} assignments x #{num_groupings} groupings..."

      existing_ta = course.tas.first
      ta = existing_ta || FactoryBot.create(:ta, course: course)
      ta_created = existing_ta.nil?
      assignment_ids = []

      ActiveRecord::Base.transaction do
        num_assignments.times do |i|
          assignment = FactoryBot.create(
            :assignment,
            course: course,
            short_identifier: "BENCH#{i}_#{timestamp}",
            due_date: 1.week.ago,
            assignment_properties_attributes: { vcs_submit: true }
          )
          assignment_ids << assignment.id

          FactoryBot.create(:rubric_criterion, assignment: assignment)

          num_groupings.times do |j|
            group = FactoryBot.create(
              :group,
              course: course,
              group_name: "bench_#{i}_#{j}_#{timestamp}"
            )
            grouping = FactoryBot.create(
              :grouping_with_inviter,
              assignment: assignment,
              group: group
            )
            FactoryBot.create(:ta_membership, grouping: grouping, role: ta)

            submission = FactoryBot.create(:version_used_submission, grouping: grouping)
            grouping.update_column(:is_collected, true)

            result = submission.current_result
            result.create_marks

            if rand < complete_ratio
              result.marks.each { |m| m.update_column(:mark, rand(0..m.criterion.max_mark.to_i)) }
              result.update_column(:marking_state, Result::MARKING_STATES[:complete])
            end
          end
          print '.'
        end
      end

      puts "\nDone."
      FileUtils.mkdir_p(File.dirname(DATA_FILE))
      File.write(DATA_FILE, { assignment_ids: assignment_ids, ta_id: ta.id, ta_created: ta_created }.to_json)
    end

    desc 'Remove benchmark test data'
    task cleanup: :environment do
      unless File.exist?(DATA_FILE)
        puts 'No benchmark data found.'
        next
      end

      data = JSON.parse(File.read(DATA_FILE), symbolize_names: true)
      assignment_ids = data[:assignment_ids]

      puts "Removing #{assignment_ids.size} assignments..."

      ActiveRecord::Base.transaction do
        # Get IDs before deleting
        group_ids = Grouping.where(assessment_id: assignment_ids).pluck(:group_id)
        result_ids = Result.joins(submission: :grouping)
                           .where(groupings: { assessment_id: assignment_ids }).ids

        # Get student role and user IDs before deleting memberships
        student_role_ids = StudentMembership.joins(:grouping)
                                            .where(groupings: { assessment_id: assignment_ids })
                                            .pluck(:role_id)
        student_user_ids = Role.where(id: student_role_ids).pluck(:user_id)

        # Delete in FK order
        Mark.where(result_id: result_ids).delete_all
        Result.where(id: result_ids).delete_all
        Submission.joins(:grouping).where(groupings: { assessment_id: assignment_ids }).delete_all
        Membership.joins(:grouping).where(groupings: { assessment_id: assignment_ids }).delete_all
        Grouping.where(assessment_id: assignment_ids).delete_all

        Criterion.where(assessment_id: assignment_ids).find_each { |c| c.levels.delete_all }
        Criterion.where(assessment_id: assignment_ids).delete_all
        AssignmentProperties.where(assessment_id: assignment_ids).delete_all
        SubmissionRule.where(assessment_id: assignment_ids).delete_all
        Assignment.where(id: assignment_ids).delete_all
        Group.where(id: group_ids).delete_all

        # Delete student roles and their users
        GradeEntryStudent.where(role_id: student_role_ids).delete_all
        Role.where(id: student_role_ids).delete_all
        User.where(id: student_user_ids).delete_all

        # Delete TA if it was created by benchmark
        if data[:ta_created]
          ta = Role.find_by(id: data[:ta_id])
          if ta
            ta_user_id = ta.user_id
            GraderPermission.where(role_id: ta.id).delete_all
            ta.delete
            User.where(id: ta_user_id).delete
          end
        end
      end

      File.delete(DATA_FILE)
      puts 'Done.'
    end
  end
end
