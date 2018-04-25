class CreateIndividualGroupsForAllStudentsJob < ApplicationJob

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
    return unless assignment.group_max == 1

    students = Student.where(hidden: false)
    progress.total = students.count

    students.find_each do |student|
      # Check to see if the student already has a grouping for
      # the current assignment
      unless student.accepted_grouping_for(assignment.id).nil?
        progress.increment
        next
      end

      begin
        ApplicationRecord.transaction do
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
      rescue => e
        Rails.logger.error e.message
      end
    end

    # Generate the permissions file for all valid groups
    Repository.get_class.update_permissions
    m_logger = MarkusLogger.instance
    m_logger.log('Creating all individual groups completed',
                 MarkusLogger::INFO)
    puts 'Creating all groups complete'
  end
end
