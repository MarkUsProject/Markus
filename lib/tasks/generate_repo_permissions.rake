namespace :markus do
  desc 'Generates the repo permission file'
  task generate_repo_permissions: :environment do
    Repository.get_class.update_permissions
  end
end
