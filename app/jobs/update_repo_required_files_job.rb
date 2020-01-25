class UpdateRepoRequiredFilesJob < ApplicationJob

  queue_as Rails.configuration.x.queues.repo_required_files

  def self.show_status(status)
    I18n.t('poll_job.update_repo_required_files_job', progress: status[:progress], total: status[:total])
  end

  def perform(assignment_id, user_name)
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    required_files = Assignment.get_required_files.to_json
    progress.total = assignment.groupings.count
    assignment.each_group_repo do |repo|
      txn = repo.get_transaction(user_name, I18n.t('repo.commits.required_files',
                                                   assignment: assignment.short_identifier))
      txn.replace('.required.json', required_files, 'application/json', repo.get_latest_revision.revision_identifier)
      repo.commit(txn)
      progress.increment
    end
  end
end
