class UpdateStarterCodeJob < ApplicationJob

  queue_as MarkusConfigurator.markus_job_update_starter_code_queue_name

  def perform(assignment_id)
    assignment = Assignment.includes(groupings: :group).find(assignment_id)
    assignment_folder = assignment.repository_folder
    assignment.access_starter_code_repo do |starter_repo|
      starter_revision = starter_repo.get_latest_revision
      next unless starter_revision.path_exists?(assignment_folder)
      internal_file_names = Repository.get_class.internal_file_names
      tree = starter_revision.tree_at_path(assignment_folder)
      assignment.each_group_repo do |repo|
        txn = repo.get_transaction('Markus', I18n.t('repo.commits.starter_code',
                                                    assignment: assignment.short_identifier))
        tree.each do |starter_file_name, starter_obj|
          next if internal_file_names.include?(starter_file_name)
          starter_file_path = File.join(assignment_folder, starter_file_name)
          if starter_obj.is_a? Repository::RevisionDirectory
            txn.add_path(starter_file_path)
          elsif revision.path_exists?(starter_file_path)
            txn.replace(starter_file_path, starter_repo.download_as_string(starter_obj), starter_obj.mime_type,
                        revision.revision_identifier)
          else
            txn.add(starter_file_path, starter_repo.download_as_string(starter_obj), starter_obj.mime_type)
          end
        end
        if txn.has_jobs?
          repo.commit(txn)
          # TODO starter code identifier has a meaning now?
          # TODO handle errors
          # TODO make function that can be used in Grouping#create_grouping_repository_folder too
          # TODO Optimize download_as_string in a hash?
        end
      end
    end
  end
end
