# Need to create a resque worker to listen to default queue to perform the job
# VVERBOSE=1 QUEUE=default rake environment resque:work
class CreateIndividualGroupsForAllStudentsJob < ActiveJob::Base
  queue_as :default

  def perform(assignment_id)

    assignment = Assignment.find_by_id(assignment_id)
    if assignment.group_max == 1
      Student.all.map do |student|
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
              # TODO: need to output an error.
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
        end
      end

      # The generation of the permissions file for all valid groups
      Repository::SubversionRepository.__generate_authz_file

    end
  end
end
