class CreateIndividualGroupsForAllStudentsJob < ActiveJob::Base
  queue_as MarkusConfigurator.markus_job_create_individual_groups_queue_name

  before_enqueue do |_job|
    job_messenger = JobMessenger.create(job_id: job_id, status: :queued)
    PopulateCache.populate_for_job(job_messenger, job_id)
  end

  def perform(assignment)
    begin
      # Update our messenger and populate the cache with its new status
      job_messenger = JobMessenger.where(job_id: job_id).first
      job_messenger.update_attributes(status: :running)
      PopulateCache.populate_for_job(job_messenger, job_id)

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
        repo = Repository.get_class(MarkusConfigurator.markus_config_repository_type)
        repo.__set_all_permissions
        m_logger = MarkusLogger.instance
        m_logger.log('Creating all individual groups completed',
                     MarkusLogger::INFO)
        puts 'Creating all groups complete'

      end
    rescue => e
      Rails.logger.error e.message
      job_messenger.update_attributes(status: :failed, message: e.message)
      PopulateCache.populate_for_job(job_messenger, job_id)
      raise e
    end
      job_messenger.update_attributes(status: :succeeded)
      PopulateCache.populate_for_job(job_messenger, job_id)
  end
end
