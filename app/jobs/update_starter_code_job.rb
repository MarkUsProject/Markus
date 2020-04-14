class UpdateStarterCodeJob < ApplicationJob

  queue_as Rails.configuration.x.queues.update_starter_code

  def self.show_status(status)
    I18n.t('poll_job.update_starter_code_job', progress: status[:progress], total: status[:total])
  end

  def perform(assignment_id, overwrite)
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    return unless Repository.get_class.repository_exists?(assignment.starter_code_repo_path)

    assignment_folder = assignment.repository_folder
    assignment.access_starter_code_repo do |starter_repo|
      starter_revision = starter_repo.get_latest_revision
      next unless starter_revision.path_exists?(assignment_folder)

      starter_tree = starter_revision.tree_at_path(assignment_folder, with_attrs: false)
      starter_files = {} # cache of starter code files
      progress.total = assignment.groupings.count
      assignment.each_group_repo do |group_repo|
        txn = assignment.update_starter_code_files(group_repo, starter_repo, starter_tree, overwrite: overwrite,
                                                   starter_files: starter_files)
        if txn.has_jobs?
          group_repo.commit(txn)
        end
        progress.increment
      end
    end
  end
end
