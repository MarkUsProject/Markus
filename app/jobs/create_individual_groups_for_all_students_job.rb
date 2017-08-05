class CreateIndividualGroupsForAllStudentsJob < ActiveJob::Base
  include ActiveJob::Status

  queue_as MarkusConfigurator.markus_job_create_individual_groups_queue_name

  def self.on_complete_js(status)
    'window.location.reload.bind(window.location)'
  end

  def self.show_status(status)
    I18n.t('poll_job.create_individual_groups_job', progress: status[:progress],
           total: status[:total])
  end

  before_enqueue do |job|
    status.update(job_class: self.class)
  end

  def perform(assignment)
    begin
      progress.total = Student.count

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
          progress.increment
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
    end
  end
end
