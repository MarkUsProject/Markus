class DownloadSubmissionsJob < ApplicationJob
  queue_as Rails.configuration.x.queues.download_submissions

  def self.show_status(status)
    I18n.t('poll_job.download_submissions_job', progress: status[:progress], total: status[:total])
  end

  def perform(groupings, zip_path, options = {})
    ## delete the old file if it exists
    File.delete(zip_path) if File.exist?(zip_path)

    zip_name = File.basename zip_path

    progress.total = groupings.size
    Zip::File.open(zip_path, Zip::File::CREATE) do |zip_file|
      groupings.each do |grouping|
        revision_id = grouping.current_submission_used&.revision_identifier
        group_name = grouping.group.repo_name
        grouping.group.access_repo do |repo|
          revision = repo.get_revision(revision_id)
          repo.send_tree_to_zip(assignment.repository_folder, zip_file, zip_name + group_name, revision)
        rescue Repository::RevisionDoesNotExist
          next
        ensure
          progress.increment
        end
      end
    end
  end

end
