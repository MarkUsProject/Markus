# Need to create a resque worker to listen to default queue to perform the job
# VVERBOSE=1 QUEUE=default rake environment resque:work
class CreateIndividualGroupsForAllStudentsJob < ActiveJob::Base
  queue_as :default

  def perform(assignment)
    if assignment.group_max == 1
      Student.find_each do |student|
        # Check to see if the student already has a grouping for
        # the current assignment
        grouping = student.accepted_grouping_for(assignment.id)
        next unless grouping.nil?

        ActiveRecord::Base.transaction do
          # If an individual repo has already been created for this user
          # then just use that one.
          group = Group.find_by(group_name: student.user_name)
          if group.nil?
            group = Group.create(
                group_name: student.user_name,
                repo_name: student.user_name)
            unless group.errors[:base].blank?
              # TODO: need to output an error.
            end
          end

          grouping = Grouping.create(
               assignment_id: assignment.id,
               group: group)

          # Create the membership
          StudentMembership.create(
            grouping_id: grouping.id,
            membership_status: StudentMembership::STATUSES[:inviter],
            user_id: student.id)
        end
      end

      # Generate the permissions file for all valid groups
      Repository::SubversionRepository.__generate_authz_file
      m_logger = MarkusLogger.instance
      m_logger.log('Creating all individual groups completed',
                   MarkusLogger::INFO)
      puts 'Creating all groups complete'

    end
  end
end
