class UpdateRepoRequiredFilesJob < ApplicationJob

  queue_as MarkusConfigurator.markus_job_update_repo_required_files_queue_name

  def perform(assignment_id, user_id)
    #TODO current_user is an object???
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    user = User.find(user_id)
    required_files = Assignment.get_required_files.to_json
    assignment.each_group_repo do |repo|
      t = repo.get_transaction(user.user_name, I18n.t('repo.commits.required_files',
                                                      assignment: assignment.short_identifier))
      t.replace('.required.json', required_files, 'application/json', repo.get_latest_revision.revision_identifier)
      repo.commit(t)
    end
  end
end
