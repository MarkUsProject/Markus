# Prepares submission files from a list of groupings for download
# by zipping them up into a single zipfile
class DownloadSubmissionsJob < ApplicationJob
  def self.show_status(status)
    if status[:progress] == status[:total]
      I18n.t('poll_job.download_submissions_finalizing')
    else
      I18n.t('poll_job.download_submissions_job', progress: status[:progress], total: status[:total])
    end
  end

  def self.completed_message(status)
    { partial: 'submissions/download_zip_file', locals: { assignment_id: status[:assignment_id],
                                                          course_id: status[:course_id] } }
  end

  before_enqueue do |job|
    self.status.update(assignment_id: job.arguments[2], course_id: job.arguments[3])
  end

  def perform(grouping_ids, zip_path, _assignment_id, _course_id)
    ## delete the old file if it exists
    FileUtils.rm_f(zip_path)

    progress.total = grouping_ids.length
    Zip::File.open(zip_path, create: true) do |zip_file|
      Grouping.includes(:group, :current_submission_used).where(id: grouping_ids).each do |grouping|
        revision_id = grouping.current_submission_used&.revision_identifier
        group_name = grouping.group.group_name
        grouping.access_repo do |repo|
          revision = repo.get_revision(revision_id)
          repo.send_tree_to_zip(grouping.assignment.repository_folder, zip_file, group_name, revision)
        rescue Repository::RevisionDoesNotExist
          next
        ensure
          progress.increment
        end
      end
    end
  end
end
