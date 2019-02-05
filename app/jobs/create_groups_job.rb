class CreateGroupsJob < ApplicationJob
  queue_as MarkusConfigurator.markus_job_create_groups_queue_name

  def self.on_complete_js(status)
    'window.location.reload.bind(window.location)'
  end

  def self.show_status(status)
    if status[:status] == :failed
      status[:error_message]
    else
      I18n.t('poll_job.create_groups_job', progress: status[:progress], total: status[:total])
    end
  end

  before_enqueue do |job|
    status.update(job_class: self.class)
  end

  def perform(assignment, data)
    progress.total = data.length
    begin
      Repository.get_class.update_permissions_after(only_on_request: true) do
        ApplicationRecord.transaction do
          data.each do |group_name, repo_name, *members|
            begin
              group = Group.find_or_create_by!(group_name: group_name, repo_name: repo_name)
            rescue ActiveRecord::RecordInvalid => e
              status.update(error_message: group.errors.full_messages.join("\n"))
              raise
            end

            member_hash = StudentMembership.joins(:grouping)
                                           .joins(:user)
                                           .where('groupings.group_id': group.id)
                                           .where(membership_status: [:inviter, :accepted])
                                           .pluck('groupings.assignment_id', 'users.user_name')
                                           .group_by(&:first)
                                           .transform_values { |g| Set.new g.map(&:second) }

            if member_hash.empty? || Set.new(members) == member_hash.values.first
              # The set of members does not conflict with other members associated with other
              # groupings for this group
              unless member_hash.include? assignment.id
                begin
                  grouping = Grouping.create(group: group, assignment: assignment)
                rescue ActiveRecord::RecordInvalid => e
                  status.update(error_message: group.errors.full_messages.join("\n"))
                  raise
                end
                user_count = 0
                User.where(user_name: members).find_each.with_index do |student, i|
                  user_count += 1
                  member_status = i == 0 ?
                                    StudentMembership::STATUSES[:inviter] :
                                    StudentMembership::STATUSES[:accepted]
                  begin
                    StudentMembership.find_or_create_by!(user: student,
                                                         membership_status: member_status,
                                                         grouping: grouping)
                  rescue ActiveRecord::RecordInvalid => e
                    status.update(error_message: group.errors.full_messages.join("\n"))
                    raise
                  end
                end
                if user_count != members.length
                  # A member in the members list is not a User in the database
                  bad_names = (Set.new(members) - Set.new(User.where(user_name: members).pluck(:user_name))).join(', ')
                  msg = I18n.t('csv.member_does_not_exist', group_name: group_name, student_user_name: bad_names)
                  status.update(error_message: msg)
                  raise CSVInvalidLineError, msg
                end
              end
            else
              if member_hash.include? assignment.id
                msg = I18n.t('csv.group_with_different_membership_current_assignment', group_name: group_name)
              else
                msg = I18n.t('csv.group_with_different_membership_different_assignment', group_name: group_name)
              end
              status.update(error_message: msg)
              raise CSVInvalidLineError, msg
            end
            progress.increment
          end
        end
      end
    rescue => e
      Rails.logger.error e.message
      raise
    end

    m_logger = MarkusLogger.instance
    m_logger.log('Creating all individual groups completed',
                 MarkusLogger::INFO)
  end
end
