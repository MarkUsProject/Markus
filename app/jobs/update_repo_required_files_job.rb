class UpdateRepoRequiredFilesJob < ActiveJob::Base

  queue_as MarkusConfigurator.markus_job_update_repo_required_files_queue_name

  def update_group_repo(group, current_user, required_files)
    repo = group.repo
    t = repo.get_transaction(current_user.user_name)
    t.replace('.required.json', required_files, 'application/json', repo.get_latest_revision.revision_identifier)
    repo.commit(t)
  end

  def perform(current_user)
    failed_groups = []
    required_files = Assignment.get_required_files.to_json
    Group.all.each do |group|
      begin
        update_group_repo(group, current_user, required_files)
      rescue
        # in the event of a concurrent repo modification, retry later
        # TODO add a repo.update api maybe and retry here?
        failed_groups.push(group)
      end
    end
    failed_groups.each do |group|
      begin
        update_group_repo(group, current_user, required_files)
      rescue
        # give up
      end
    end
  end
end
