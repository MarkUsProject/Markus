class UpdateRepoRequiredFilesJob < ApplicationJob

  queue_as MarkusConfigurator.markus_job_update_repo_required_files_queue_name

  def update_group_repo(assignment, group, current_user, required_files)
    group.access_repo do |repo|
      t = repo.get_transaction(current_user.user_name,
                               I18n.t('repo.commits.required_files', assignment: assignment.short_identifier))
      t.replace('.required.json', required_files, 'application/json', repo.get_latest_revision.revision_identifier)
      repo.commit(t)
    end
  end

  def perform(assignment_id, current_user)
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    required_files = Assignment.get_required_files.to_json
    failed_groups = []
    assignment.groupings.each do |grouping|
      begin
        group = grouping.group
        update_group_repo(assignment, group, current_user, required_files)
      rescue
        # in the event of a concurrent repo modification, retry later
        # TODO add a repo.update api maybe and retry here?
        failed_groups.push(group)
      end
    end
    failed_groups.each do |group|
      begin
        update_group_repo(assignment, group, current_user, required_files)
      rescue
        # give up
      end
    end
  end
end
