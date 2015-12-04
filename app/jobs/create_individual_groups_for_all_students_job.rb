class CreateIndividualGroupsForAllStudentsJob < ActiveJob::Base
  queue_as :default

  def perform(assignment_id)

    assignment = Assignment.find_by_id(assignment_id)
    if assignment.group_max == 1
      students.map do |student|
        # Check to see if the student already has a grouping for
        # the current assignment
        grouping = student.accepted_grouping_for(assignment.id)
        next unless grouping.nil?

        ActiveRecord::Base.transaction do
          grouping = Grouping.new
          grouping.assignment_id = assignment.id

          # If an individual repo has already been created for this user
          # then just use that one.
          group = Group.find_by group_name: student.user_name
          if group.nil?
            group = Group.new(group_name: student.user_name)
            group.repo_name = student.user_name
            group.save
            unless group.errors[:base].blank?
              # raise an error and continue
              # collision_error = I18n.t('csv.repo_collision_warning',
              #                          repo_name: group.errors[:base],
              #                          group_name: group.group_name)
              # # flash_message(:error,
              #               'Student ' + student.user_name + ': ' + \
              #                collision_error)
            end
          end

          grouping.group = group
          grouping.save
          # Create the membership
          member = StudentMembership.new(
            grouping_id: grouping.id,
            membership_status: StudentMembership::STATUSES[:inviter],
            user_id: student.id)
          member.save
          # Update repo permissions if need be. This has to happen
          # after memberships have been established.
          grouping.update_repository_permissions
          # Add permissions for TAs and admins.  This completely rerwrites the
          # auth file but that shouldn't be a big deal in this case.
          group.set_repo_permissions
        end
      end
    end
  end
end
