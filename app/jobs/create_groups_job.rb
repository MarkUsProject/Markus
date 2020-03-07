# create groups job
class CreateGroupsJob < ApplicationJob
  queue_as Rails.configuration.x.queues.create_groups

  def self.on_complete_js(_status)
    '() => {window.groupsManager && window.groupsManager.fetchData()}'
  end

  def self.show_status(status)
    I18n.t('poll_job.create_groups_job', progress: status[:progress], total: status[:total])
  end

  def log_creation
    begin
      obj = yield
    rescue ActiveRecord::RecordInvalid => e
      status.update(error_message: e.message)
      raise
    end
    unless obj.errors.blank?
      msg = obj.errors.full_messages.join("\n")
      status.update(error_message: msg)
      Rails.logger.error msg
      raise ActiveRecord::Rollback
    end
    obj
  end

  def perform(assignment, data)
    progress.total = data.length
    Repository.get_class.update_permissions_after(only_on_request: true) do
      ApplicationRecord.transaction do
        data.each do |group_name, repo_name, *members|
          group = log_creation { Group.find_or_create_by(group_name: group_name, repo_name: repo_name) }
          member_hash = StudentMembership.joins(:grouping)
                                         .joins(:user)
                                         .where('groupings.group_id': group.id)
                                         .where(membership_status: [:inviter, :accepted])
                                         .pluck('groupings.assessment_id', 'users.user_name')
                                         .group_by(&:first)
                                         .transform_values { |g| Set.new g.map(&:second) }

          if member_hash.empty? || Set.new(members) == member_hash.values.first
            # The set of members does not conflict with other members associated with other
            # groupings for this group
            unless member_hash.include? assignment.id
              grouping = log_creation { Grouping.find_or_create_by(group: group, assignment: assignment) }
              user_count = 0
              User.where(user_name: members).find_each.with_index do |student, i|
                user_count += 1
                if i.zero?
                  member_status = StudentMembership::STATUSES[:inviter]
                else
                  member_status = StudentMembership::STATUSES[:accepted]
                end
                log_creation do
                  StudentMembership.find_or_create_by(user: student,
                                                      membership_status: member_status,
                                                      grouping: grouping)
                end
              end
              if user_count != members.length
                # A member in the members list is not a User in the database
                all_users = Set.new User.where(user_name: members).pluck(:user_name)
                bad_names = (Set.new(members) - all_users).to_a.join(', ')
                msg = I18n.t('csv.member_does_not_exist', group_name: group_name, student_user_name: bad_names)
                status.update(error_message: msg)
                Rails.logger.error msg
                raise ActiveRecord::Rollback
              end
            end
          else
            if member_hash.include? assignment.id
              msg = I18n.t('csv.group_with_different_membership_current_assignment', group_name: group_name)
            else
              msg = I18n.t('csv.group_with_different_membership_different_assignment', group_name: group_name)
            end
            status.update(error_message: msg)
            Rails.logger.error msg
            raise ActiveRecord::Rollback
          end
          progress.increment
        rescue ActiveRecord::Rollback
          status[:error_message] = "#{status[:error_message]};#{I18n.t('poll_job.create_groups_job_extra_info',
                                                                       group_name: group_name,
                                                                       repo_name: repo_name,
                                                                       members: members)}"
          raise
        end
      end
    end
    m_logger = MarkusLogger.instance
    m_logger.log('Creating all individual groups completed',
                 MarkusLogger::INFO)
  end
end
