class UpdateRepoMaxFileSizeJob < ApplicationJob
  def self.show_status(status)
    I18n.t('poll_job.update_repo_max_file_size_job', progress: status[:progress], total: status[:total])
  end

  def perform(course_id)
    course = Course.find(course_id)
    progress.total = course.groups.count
    course.each_group_repo do |repo|
      txn = repo.get_transaction('Markus', I18n.t('repo.commits.max_file_size'))
      revision = repo.get_latest_revision
      # This check is for backwards compatability in case repos exist without the .max_file_size file
      if revision.path_exists?('.max_file_size')
        txn.replace('.max_file_size', course.max_file_size.to_s, 'text/plain', revision.revision_identifier)
      else
        txn.add('.max_file_size', course.max_file_size.to_s, 'text/plain')
      end
      repo.commit(txn)
      progress.increment
    end
  end
end
