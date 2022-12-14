class UpdateRepoRequiredFilesJob < ApplicationJob
  def self.show_status(status)
    I18n.t('poll_job.update_repo_required_files_job', progress: status[:progress], total: status[:total])
  end

  def perform(assignment_id)
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    required_files = assignment.course.get_required_files
    progress.total = assignment.groupings.count
    assignment.each_group_repo do |repo|
      txn = repo.get_transaction('Markus', I18n.t('repo.commits.required_files',
                                                  assignment: assignment.short_identifier))
      revision = repo.get_latest_revision
      # This check is for backwards compatability in case repos exist with the old .required.json file instead
      if revision.path_exists?('.required')
        txn.replace('.required', required_files, 'text/plain', revision.revision_identifier)
      else
        txn.add('.required', required_files, 'text/plain')
      end
      repo.commit(txn)
      progress.increment
    end
  end
end
